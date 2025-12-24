#!/usr/bin/env julia

# parse a MD file with embedded Julia codes into a project
# In this level, this script aims to do:
#    - Extract codes from a Markdown file
#    - Detect Julia and Shell type
#    - Write codes into different files

using Printf, TOML

function print_help()
    println("""
CN0.jl

    Usage: CN0.jl COMMAND ARGUMENTS...

Commands and Arguments:

    -h, --help, help
        Prints this message.

    mark /path/to/input_file.md /path/to/output_file.md
        Mark the file with an integer. 0 plain text, 9999 unknown code, 1-?, code in different language

    parse /path/to/file.md /path/to/project
        Parse a Markdown file with embedded Julia codes into a directory.

    run /path/to/project
        Run the project according to the discriptions in MD file.
""")
    return nothing
end

if length(ARGS) < 1
    print_help()
    exit(0)
end

if "--help" in ARGS || "-h" in ARGS || "help" in ARGS
    print_help()
    exit(0)
end

struct CodeType
    i::Int
    tag::String
    suffix::String
end

function CodeType(i::Int, tag::String, t::Dict)
    return CodeType(i, tag, t["suffix"])
end

const UNKNOWN_CODE_TYPE = 9999
const CODE_TAG_SETTING = let
    t = TOML.parsefile(joinpath(@__DIR__, "taglist.toml"))
    ks = collect(keys(t))
    s = Vector{CodeType}(undef, length(ks))
    for i = eachindex(ks)
        s[i] = CodeType(i+1, ks[i], t[ks[i]])
    end
    s
end

TYPE_TAG_TO_SETTING = Dict{String,CodeType}()

for ts = CODE_TAG_SETTING
    TYPE_TAG_TO_SETTING[ts.tag] = ts
end

TYPE_LIST = map(ts -> ts.tag, CODE_TAG_SETTING)

function mark_lines(lines::Vector{String})
    line_type = zeros(Int, length(lines))

    reference_type = 0
    for i = eachindex(line_type)
        if startswith(lines[i], "```")
            line_type[i] = 1
            if iszero(reference_type)
                tag_string = String(replace(lines[i][4:end], ' '=>'-'))
                if tag_string in TYPE_LIST
                    reference_type = TYPE_TAG_TO_SETTING[tag_string].i
                else
                    reference_type = UNKNOWN_CODE_TYPE
                end
            else
                reference_type = 0
            end
        else
            line_type[i] = reference_type
        end
    end
    return line_type
end

if ARGS[1] == "mark"
    if length(ARGS) < 3
        @error "Not enough arguments for run command."
        print_help()
        exit(0)
    end

    input_file_path = abspath(ARGS[2])
    @info "Input Markdown file: $(input_file_path)"

    output_file_path = abspath(ARGS[3])
    @info "Output Markdown file: $(output_file_path)"

    if !isfile(input_file_path)
        @error "Input Markdown file not found."
        exit(0)
    end

    if isfile(output_file_path)
        @warn "Output file already exists."
    end

    @info "Read MD file"
    lines_in_md_file = readlines(input_file_path)

    @info "Detect line type"
    line_type = mark_lines(lines_in_md_file)

    @info "Write to output MD File: $output_file_path "
    open(output_file_path, "w") do io
        for i = eachindex(line_type)
            @printf(io, "%3d %s\n", line_type[i], lines_in_md_file[i])
        end
    end
    exit(0)
end

if ARGS[1] == "parse"
    if length(ARGS) < 3
        @error "Not enough arguments for parse command."
        print_help()
        exit(0)
    end

    input_file_path = abspath(ARGS[2])
    @info "Input Markdown file: $(input_file_path)"
    target_project_dir = abspath(ARGS[3])
    @info "Target project directory: $(target_project_dir)"

    if !isfile(input_file_path)
        @error "Input Markdown file not found."
        exit(0)
    end

    if isdir(target_project_dir)
        @warn "Target project directory already exists."
    end

    @info "Read MD file"
    lines_in_md_file = readlines(input_file_path)

    @info "Detect line type"
    line_type = mark_lines(lines_in_md_file)

    @info "Split code segments"
    flag_code_segment_beginning = falses(length(line_type))
    flag_code_segment_ending = falses(length(line_type))
    if line_type[1] == 1
        flag_code_segment_beginning[1] = true
    end
    if line_type[end] == 1
        flag_code_segment_ending[end] = true
    end
    for i = eachindex(line_type)
        if i == 1
            continue
        end
        if line_type[i] == 1
            if iszero(line_type[i-1])
                flag_code_segment_beginning[i] = true
            else
                flag_code_segment_ending[i] = true
            end
        end
    end
    code_segment_beginning = findall(flag_code_segment_beginning)
    code_segment_ending = findall(flag_code_segment_ending)

    @info "Create project directory"
    mkpath(target_project_dir)
    @info "Write segments to files"
    input_file_name_without_ext = let
        (_, a) = splitdir(input_file_path)
        (b, _) = splitext(a)
        b
    end
    for i = eachindex(code_segment_beginning)
        if code_segment_ending[i] - code_segment_beginning[i] == 1
            continue
        end
        type_integer = line_type[code_segment_beginning[i]+1]

        if type_integer < UNKNOWN_CODE_TYPE
            tmp_file_name = "$(input_file_name_without_ext)_segment_$(i).$(CODE_TAG_SETTING[type_integer-1].tag)$(CODE_TAG_SETTING[type_integer-1].suffix)"
        else
            tmp_file_name = "$(input_file_name_without_ext)_segment_$i.unknown.code"
        end
        tmp_file_path = joinpath(target_project_dir, tmp_file_name)
        @info "    $tmp_file_name"
        open(tmp_file_path, "w") do io
            segment_index = (code_segment_beginning[i]+1):(code_segment_ending[i]-1)
            println.(io, lines_in_md_file[segment_index])
        end
    end

    exit(0)
end

if ARGS[1] == "run"
    if length(ARGS) < 2
        @error "Not enough arguments for run command."
        print_help()
        exit(0)
    end

    exit(0)
end

@warn "Nothing to do with the provided argument."
print_help()
