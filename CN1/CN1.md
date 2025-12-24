# CodeNote level 1

## Type defines

### Code Segment Type Defines

```julia include
struct CodeType
    i::Int
    tag::String
    suffix::String
    process::String
end

function CodeType(i::Int, tag::String, t::Dict)
    return CodeType(i, tag, t["suffix"], t["process"])
end

const UNKNOWN_CODE_TYPE = 9999
const CODE_TAG_SETTING = let
    t = TOML.parsefile(joinpath(@__DIR__, "..", "taglist.toml"))
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
```

## Julia functions

There might be different process, so for a type, we need to define
a struct to save different process.

It is still needed to detect line type with more possible type, a variable list
is more useful.

```julia
function tag_lines(lines::Vector{String}, type_dict::Dict{String,Int})
    line_type = zeros(Int, length(lines))
    dk = keys(type_dict)

    reference_type = 0
    for i = eachindex(line_type)
        if startswith(lines[i], "```")
            line_type[i] = 1
            if iszero(reference_type)
                tag_string = String(lines[i][4:end])
                if tag_string in dk
                    reference_type = type_dict[tag_string]
                else
                    reference_type = 9999
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
```
