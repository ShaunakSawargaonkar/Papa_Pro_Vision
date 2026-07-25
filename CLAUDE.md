# Graphify-first workflow

When working in this repository, use Graphify before scanning the full codebase.

Graphify output is available at:

- `graphify-out/graph.json`
- `graphify-out/GRAPH_REPORT.md`
- `graphify-out/graph.html`

For architecture, feature planning, dependency analysis, refactoring, data-flow, impact analysis, or “where should I change this?” questions, first run:

```bash
graphify query "<the user's question>"