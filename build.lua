-- Build configuration for ngelesson
-- Matthew Leingang, 2019-05-29

module = "ngelesson"

unpackfiles = {"*.dtx"}
typesetfiles = {"*.dtx"}


-- The "luatex" engine produces some very minor differences (like, a single
-- space in a \kern line).  One way around that is to disable the luatex engine:
-- (uncomment to activate)
--
--     checkengines = {"pdftex", "xetex"}
--
-- Another way is to save test logs twice (on command line)
--
--     $ l3build save test
--     $ l3build save -e luatex test
--
-- This creates both "test.tlg" and "test.luatex.ltg" in testfiles.
-- Engine-specific tlg files are only compared with the specific engines.


function update_tag(file,content,tagname,tagdate)
    -- This should go in a pre-tag hook, but there isn't one.
    -- ensure that the tagname matches `v`x.y.z
    assert(string.match(tagname,"^v%d+%.%d+%.%d+$"),
        "invalid tag name. Use a literal v, then a semantic version number.")
    -- Make sure the working directory is "clean".
    -- See https://unix.stackexchange.com/a/394674/62853
    assert(os.execute("git diff-index --quiet HEAD") == 0,
        "Working directory dirty.  Commit changes and try again.")
    -- TeX dates are in yyyy/mm/dd format.  tagdate is in yyyy-mm-dd format.
    tagdate_tex = string.gsub(tagdate,'-','/')
    if string.match(file, "%.dtx$") then
        content = string.gsub(content,
            "\n%%<classes>%[%d%d%d%d/%d%d/%d%d v.- ",
            "\n%%<classes>[" .. tagdate_tex .. " " .. tagname .. " "
    )
        content = string.gsub(content,
            "\n%% \\changes{unreleased}",
            "\n%% \\changes{" .. tagname .. "}"
        )
        return content
    end
end


function tag_hook(tagname,tagdate)
    -- handle version control
    os.execute("git add .")
    os.execute("git commit -m \"Log changes for version " .. tagname .. "\"")
    return os.execute("git tag -a -m \"Tag version " .. tagname .. "\" " .. tagname)
end


kpse.set_program_name("texlua")
if not release_date then
   dofile(kpse.lookup("l3build.lua"))
end
