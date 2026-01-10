export const BeepPlugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await $`printf '\a'`
      }
    },
  }
}
