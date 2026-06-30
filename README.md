# Contexto

Frequentemente quando codificamos no ecossistema Salesforce nos deparamos com a seguinte situação: um usuário não pode executar determinada ação por si próprio, mas essa mesma ação deve ser realizada pelo sistema por alguma automação ou por algum fluxo encadeado para maior controle e clareza de usuário.

Considere uma regra de negócio no qual o status de um registro de lead não possa ser alterado manualmente de "Novo" -> "Em qualificação" pelo usuário comum, esse procedimento deverá ser executado automaticamente pelo sistema ao detectar o preenchimento dos campos customizados: "ProdutoInteresse__c", "OrcamentoDisponivel__c" e "ResultadoPrimeiroContato__c". 

Para atender esse requisito, podemos criar uma Custom Permission CP_LeadQualificationTransiction e atribuir ela a um Permission Set nomeado PS_LeadAdminAccess, criando uma Validation Rule VR_BlockUnauthorizedStatusTransiction que possui a lógica de "Se o status está sendo alterado para 'Em qualificação' e o usuário executor **não** possui a Custom Permission CP_LeadQualificationTransiction, então deverá bloquear a operação".

```
AND(
    ISPICKVAL(Status, "EmQualificacao"),
    ISPICKVAL(PRIORVALUE(Status), "Novo"),
    NOT($Permission.CP_LeadQualificationTransiction)
)
```

Quando o usuário sem o PS_LeadAdminAccess atribuído a si mesmo tenta realizar a mudança de status no lead o erro é exibido devidamente. Contudo, essa validação impedirá que o requisito `esse procedimento deverá ser executado automaticamente pelo sistema ao detectar...` seja atendido, por conta de que as automações no Salesforce sempre são acionadas com base no usuário que disparou o gatilho, e como ele não terá a permissão, o processo irá esbarrar no mesmo erro visualizado pela pessoa que tenta realizar manualmente.

# Solução

Utilizando um **Custom Setting** hierárquico, é possível criar um objeto customizado BypassSettings__c com um campo Enabled__c para armazenar a informação de qual usuário possui a permissão temporária para efetuar o bypass ou não.

Cada registro de uma hierárquia de custom setting possui um nível de acesso, podendo ser definido um estado para todos os usuários de um determinado perfil, ou para cada usuário em específico. O serviço Apex BypassService procura por um bypass já existente com base no Id da sessão do usuário autenticado através da instrução `BypassSettings__c bypass = BypassSettings__c.getValues(UserInfo.getUserId());`, posteriormente inserindo um registro apto para bypass (Enabled__c=true) caso não encontrado, ou atualizando o valor do campo do registro existente para verdadeiro. Entre o liga e desliga do bypass, o método realiza um upsert no registro recebido pelo argumento, garantindo que a condição de bloqueio da Validation Rule não seja satisfeita naquela transação.

Criado esse custom setting, voltamos à Validation Rule VR_BlockUnauthorizedStatusTransiction para adicionarmos uma linha cuja responsabilidade é: garantir que o erro só vai acontecer se durante a operação não existir um registro de bypass associado ao usuário da transação com valor igual a verdadeiro. A atualização da regra pode ser visualizada abaixo.

```
//NOVA VALIDATION
AND(
    ISPICKVAL(Status, 'EmQualificacao'),
    ISPICKVAL(PRIORVALUE(Status), 'Novo'),
    NOT( $Permission.CP_LeadQualificationTransiction ),
    NOT($Setup.BypassSettings__c.Enabled__c ) // <----- linha adicionada
)
```

Deste modo, o usuário não consegue definir por conta própria o valor de Status como "Em qualificação", mas a automação que executa por trás possui autonomia para manipular o registro e realizar as alterações sem que as validações existentes sejam um empecilho.

# Demonstração

[![Assistir no YouTube](https://img.youtube.com/vi/1MYItUgWNus/0.jpg)](https://www.youtube.com/watch?v=1MYItUgWNus)

# Componentes desenvolvidos

| Nome    | API Name | Tipo de componente | Ação |
| -------- | ------- | -----------------  | ---- |
| CP Lead Qualification Transiction  | CP_LeadQualificationTransiction    | CustomPermission | Criação
| PS Lead Admin Access | PS_LeadAdminAccess     | PermissionSet | Criação
| Resultado do primeiro contato    | ResultadoPrimeiroContato__c    | CustomField (Lead) | Criação
| Produto de interesse  | ProdutoInteresse__c    | CustomField (Lead) | Criação
| Orçamento disponível | OrcamentoDisponivel__c     | CustomField (Lead) | Criação
| Enabled | 	Enabled__c | CustomField (BypassSettings__c) | Criação |
| Lead Status | Status | CustomField (Lead) | Atualização |
| [Lead] Altera status de "Novo" para "Em qualificação" | LeadAlteraStatusNovoparaEmQualificacao | FlowDefinition | Criação |
| Bypass Settings | BypassSettings__c | CustomSetting | Criação |
| BypassService | BypassService | ApexClass | Criação |
| BypassController | BypassController | ApexClass | Criação |
| VR_BlockUnauthorizedStatusTransiction | VR_BlockUnauthorizedStatusTransiction | ValidationRule | Criação |
