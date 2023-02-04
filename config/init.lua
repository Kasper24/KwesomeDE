-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
-- Only runs this on my system, other don't need it
if os.getenv("USER") == 'kasper' then
    require(... .. ".startup")
end

require(... .. ".apps")
require(... .. ".layouts")
require(... .. ".tags")
require(... .. ".keys")
require(... .. ".rules")
require(... .. ".ranger")
