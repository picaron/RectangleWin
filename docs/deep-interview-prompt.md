# 🤖 Claude Code: Deep Interview Prompt

A **"deep interview prompt"** guide shared by Anthropic's Claude Code tech lead (Thariq) that generated significant attention. This prompt leverages the `AskUserQuestionTool` to deeply understand user intent and achieve perfect strategic alignment between the model and the user.

## 🌟 Core Concept

> **"Share every context of the project in my mind with Claude Code"**

Beyond simple code generation, this prompt has Claude ask questions in return about technical trade-offs, UI/UX details, and potential risks that may arise during the planning phase — raising implementation accuracy to 99% or higher.

---

## 📋 Interview Prompt (Copy & Paste)

Enter the following in the Claude Code terminal or reference it when starting a specific task.

```markdown
Read the @SPEC.md file and use the AskUserQuestionTool to conduct a thorough interview with me covering all aspects including technical implementation, UI & UX, concerns, trade-offs, and more.

Questions should not be trivial or generic; they should approach the topic at great depth. Continue the interview until the content is complete. Once the interview is finished, finalize and write the spec to a file based on what was discussed.

```

---

## 🚀 Usage Guide and Tips

### 1. Environment

* Works best with **Claude Code**'s `Plan Mode`.
* Run when you have a written `SPEC.md` or planning draft.

### 2. Interview Depth

* Goes beyond simple feature implementation questions — expect **15 to 60+ questions** exchanged to refine the design.
* The Q&A process itself becomes a documentation process.

### 3. Expected Benefits

* **Strategic Alignment:** Aligns what the user envisions with Claude's understanding before development begins.
* **Edge Case Discovery:** Identify unconsidered UI/UX edge cases or technical constraints in advance.
* **Improved Accuracy:** Code generated after a deep interview drastically reduces the number of revisions needed.

---

## 📈 Real-World Cases (Testimonials)

* **Anthropic Engineer (Thariq):** Shared on X (formerly Twitter), saved by over 12,000 people.
* **Case A:** Adding 2 simple UX features — 15 deep questions yielded results matching the original vision at 99%.
* **Case B:** Starting a new project — exchanged 63 questions to maximize design completeness.

---

## 🔗 Related Links

* [Original Post by Anthropic's Thariq](https://www.google.com/search?q=https://x.com/thariq/status/1888319662135017551)

---

*Last Updated: 2026-01-12*

---

You might find this prompt helpful for improving design quality when applied to the `@SPEC.md` files of your current **Go-based Windows utility projects** or **AI voice interface projects**.

Would you like to adapt this prompt further for a specific project (e.g., adding Go-language-specific questions)?