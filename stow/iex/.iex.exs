# iex config
IEx.configure(
    alive_prompt: "%prefix(%node):%counter>",
    default_prompt: "%prefix:%counter>",
    colors: [eval_result: [:magenta, :bright]],
    inspect: [limit: -1]
)
