return {
    read_globals = { "describe", "it" },

    stds = {
        busted = {
            read_globals = {
                "describe",
                "it",
                "before_each",
                "after_each",
                "assert",
                "spy",
            },
        },
    },
    std = "_G+busted",
}
