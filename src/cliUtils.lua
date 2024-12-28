local cliUtils = {}

---Asks a question, then returns yes/no.
---@param question string What to ask
---@param choices? table 1 letter choices, first value is yes, second is no
---@param default_no? boolean Default to no instead of yes
function cliUtils.ask(question, choices, default_no)
  default_no = default_no or false
  choices = choices or {"y", "n"}
  for _, choice in pairs(choices) do
    choice = choice:lower():sub(1, 1)
  end

  local autocomplete_function = function (partial) require("cc.completion").choice(partial, choices) end
  local yes_text = (default_no and choices[1] or choices[1]:upper())
  local no_text = (default_no and choices[2]:upper() or choices[2])

  print(question .. " [" .. yes_text .. "/" .. no_text .. "]")
  local input = read(nil, nil, autocomplete_function):lower():sub(1, 1)
  if (default_no) then
    return input == choices[1]
  else
    return input ~= choices[2]
  end
end


return cliUtils
