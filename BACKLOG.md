# Backlog de Ideias

Ideias e sugestões para implementações futuras. Não fazem parte do fluxo atual de desenvolvimento.

---

## Database

- **Comando de init/cleanup do banco** — Adicionar subcomandos internos como `plan _init` ou `plan _cleanup` para zerar o banco de dados e recriar o schema do zero. Útil para desenvolvimento, testes e reset de ambiente.


## generic_list — Filtros de status

- **Suporte a filtros no `generic_list`** — Por padrão, `generic_list` já oculta itens com `status = 'Done'`. No futuro, adicionar flags para controlar o que é exibido:
  - `plan task list --all` — exibe todos os itens independente de status
  - `plan task list --completed` — exibe apenas itens com `status = 'Done'`
  - `plan task list --status IN_PROGRESS` — filtra por status específico
  - Aplicável a todos os objetos com status: task, project, goal

## Hierarquia GTD — `--area` obrigatório em vision

- **`vision add` deve exigir `--area AREA_NAME`** — Assim como `project add` exige `--area` e `goal add` já exige, `vision add` também deve exigir área obrigatória. Cada área ativa deve ter planos em todos os horizontes: projects (H1), goals (H3) e visions (H4).
