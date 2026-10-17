// Flags this pane's tmux window (~/.tmux/attention.sh) when opencode finishes or asks for input
export const Attention = async ({ $ }) => {
  const script = `${process.env.HOME}/.tmux/attention.sh`
  const busy = new Set()
  const mark = (state) => $`${script} ${state}`.quiet().nothrow()

  return {
    event: async ({ event: { type, properties } }) => {
      if (type === "session.status") {
        const id = properties.sessionID
        // Subagent sessions go idle while the main one keeps working
        if (properties.status.type !== "idle") busy.add(id)
        else if (busy.delete(id) && busy.size === 0) await mark("done")
      } else if (type === "permission.asked" || type === "question.asked") {
        await mark("ask")
      }
    },
  }
}
