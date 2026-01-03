---
name: codex
description: Consult OpenAI Codex for analysis, review, or research
argument-hint: "<question or request>"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

Consult Codex with the user's question or request.

**Process:**

1. **Parse the Request**
   - Understand what the user wants to ask Codex
   - Determine if additional context is needed from the codebase

2. **Gather Context (if needed)**
   - If the request references specific files or code, read them
   - Use Glob/Grep to find relevant files if not specified
   - Extract the most relevant portions

3. **Formulate and Execute**
   - Create a clear, comprehensive prompt
   - Include relevant code snippets
   - Run: `codex exec -p "PROMPT"`
   - For complex prompts with code, use heredoc:
     ```bash
     codex exec -p "$(cat <<'EOF'
     [prompt with code]
     EOF
     )"
     ```

4. **Present Results**
   - Show Codex's response clearly
   - Highlight key findings and recommendations

**Examples:**

- `/codex What's the best way to handle errors in async functions?`
- `/codex Review the auth middleware in src/middleware/auth.ts`
- `/codex Is there a bug in the payment processing logic?`
- `/codex How should I structure the database schema for this feature?`

**Tips:**
- Be specific in your question for better results
- Reference specific files if relevant
- Codex responses may take 30-60 seconds
