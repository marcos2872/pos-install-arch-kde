# agent.md — Como obter contexto do projeto e gerenciar scripts

Este documento orienta um agente (runner/automation bot) a:
- Carregar o contexto mínimo necessário do repositório para operar corretamente.
- Adicionar ou remover scripts de instalação de forma segura e padronizada.

## 1) Contexto do projeto

Para executar com previsibilidade, o agente precisa entender a estrutura do projeto e a orquestração dos módulos.

- Estrutura essencial:
  - `pos-install-fedora-kde/` — raiz do projeto
    - `install_apps.sh` — orquestra a ordem de execução dos módulos
    - `scripts/` — contém os módulos individuais, por exemplo: `dev_tools.sh`, `rust.sh`, `node.sh`, etc.
    - `README.md` — visão geral
    - `agent.md` — este guia

- Fonte de verdade da ordem:
  - O arquivo `install_apps.sh` define a sequência oficial dos módulos. O agente deve inferir a ordem e o conjunto de módulos a partir dele.
  - Complemento remoto: existe também um instalador remoto `install_apps_remote.sh` que espelha a ordem em sua variável `MODULE_ORDER`. O agente deve ler esse arquivo (quando presente) para confirmar a ordem usada pelo instalador remoto e para permitir execução/validação remota sem clonar o repositório.
  - Convenção: o instalador normalmente chama cada script dentro de `scripts/` na ordem definida por uma lista/array e/ou blocos sequenciais.
  - Regra de consistência: ao adicionar ou remover módulos, atualize tanto `install_apps.sh` quanto `install_apps_remote.sh` (se aplicável) para manter a ordem sincronizada. Se houver divergência entre as duas fontes, priorize `install_apps.sh` para execuções locais e reporte a discrepância para revisão.

- Como o agente obtém o contexto:
  1) Ler `install_apps.sh` para:
     - Identificar a lista e a ordem dos módulos.
     - Verificar se há variáveis de controle (ex.: filtros, flags) que impactam a execução.
  2) Listar `scripts/` para:
     - Mapear quais módulos existem fisicamente.
     - Detectar novos módulos não referenciados em `install_apps.sh` ou entradas obsoletas.
  3) Cruzar as duas fontes:
     - Tudo o que aparece em `install_apps.sh` deve existir em `scripts/`.
     - Scripts presentes em `scripts/` e ausentes em `install_apps.sh` não são executados pelo instalador, a menos que o agente implemente execução modular independente.

- Heurísticas úteis para o agente:
  - Priorize a ordem em `install_apps.sh` se houver divergência.
  - Considere que cada módulo é um shell script autocontido, normalmente idempotente e com dependências próprias.
  - Se o projeto usar variáveis como `AGENT_ONLY` ou `AGENT_SKIP`, elas devem ser interpretadas somente se presentes em `install_apps.sh`. Caso contrário, o agente pode oferecer seus próprios filtros sem alterar o repositório.

## 2) Como adicionar um novo script

Siga este fluxo para incorporar um novo módulo:

- Passo a passo:
  1) Criar o script em `scripts/`:
     - Nome padronizado: `meu_modulo.sh`
     - Cabeçalho recomendável:
       - Verificações de pré-requisito (ex.: `command -v ...`)
       - Saída clara, log amigável e `exit 0` em sucesso, `exit != 0` em falha
       - Idempotência básica (não duplicar configurações/instalações quando possível)
  2) Referenciar o novo módulo em `install_apps.sh`:
     - Adicionar o nome do arquivo na lista/array de módulos ou no bloco de execução sequencial, respeitando a ordem usada pelo projeto.
     - Se houver menu, flags ou filtros, incluir o novo módulo neles.
  3) Validar:
     - Rodar apenas o novo script isoladamente para testar.
     - Rodar o instalador completo e confirmar que o módulo aparece na sequência correta.
  4) Documentar:
     - Breve nota em `README.md` sobre o que o módulo faz.
     - Se houver pós-condições ou validações, descrevê-las (opcional, mas recomendado).

- Convenções recomendadas:
  - Scripts devem viver em `scripts/`.
  - Uso de saída padrão e erros em linhas claras para facilitar logs.
  - Evitar interatividade sempre que possível; se necessário, aceitar entradas por variáveis ou STDIN.
  - Retornar códigos de saída significativos para permitir que o agente detecte falhas.

## 3) Como remover um script

Remover com segurança implica retirar referências e manter a ordem coerente:

- Passo a passo:
  1) Editar `install_apps.sh`:
     - Remover o módulo da lista/array ou bloco sequencial.
     - Retirar menções em menus, filtros ou variáveis relacionadas.
  2) Remover o arquivo de `scripts/`:
     - Excluir `scripts/meu_modulo.sh` somente após garantir que não há outras referências.
  3) Revisar documentação:
     - Atualizar `README.md` e quaisquer notas que mencionem o módulo removido.
  4) Testar:
     - Executar `install_apps.sh` para confirmar que não há referências quebradas.
     - Se o agente possui execução modular própria, atualizar seus filtros para não esperar pelo módulo removido.

- Cuidados:
  - Não deixe entradas órfãs em `install_apps.sh`.
  - Verifique se outros módulos não dependem do script removido.
  - Caso o módulo removido tenha criado configurações persistentes, considere adicionar um script de limpeza separado, se necessário.

## 4) Boas práticas de manutenção

- Ordem e coesão:
  - Mantenha a ordem estável em `install_apps.sh` para previsibilidade.
  - Agrupe módulos por tema (ex.: desenvolvimento, navegadores, personalização KDE) se a estrutura do instalador permitir.

- Padronização dos scripts:
  - Mensagens iniciais: início/fim do módulo, versão de ferramentas instaladas, ações principais.
  - Códigos de saída: `0` sucesso; `>0` falha explícita.
  - Idempotência: checar antes de instalar ou alterar; evitar duplicações em arquivos de configuração.

- Detecção automática:
  - O agente deve sempre reconstruir seu plano a partir de `install_apps.sh` e do conteúdo de `scripts/`.
  - Ao encontrar divergências, relatar: “script presente mas não referenciado” ou “referência inexistente”.

## 5) Resumo operacional para o agente

- Carregar contexto:
  - Ler `install_apps.sh` para ordem e regras.
  - Listar `scripts/` para inventário real.
  - Conciliar ambos e produzir um plano.

- Gerenciar mudanças:
  - Para adicionar: criar em `scripts/`, referenciar em `install_apps.sh`, testar, documentar.
  - Para remover: retirar referências de `install_apps.sh`, excluir o script, atualizar docs, testar.

- Objetivo:
  - Manter execução previsível, modular e auditável sem acoplar lógica ao agente que desvie das regras estabelecidas no repositório.