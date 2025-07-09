# CodeNote level 1

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
