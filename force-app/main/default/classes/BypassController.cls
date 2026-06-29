public class BypassController {

    public class Request{
        @InvocableVariable(
            label='Registros'
            description='Registros a serem atualizados pelo Apex Invocável'
            required=true
        )
        public List<SObject> records;
    }

    @InvocableMethod(
        label='Atualizar com Bypass'
        description='Atualiza o registro de modo que não esbarre em validações de usuário'
    )
    public static void execute(List<Request> requests){
        List<SObject> toUpdate = new List<SObject>();
        for(Request request : requests){
            toUpdate.addAll(request.records);
        }

        BypassService.updateWithBypass(toUpdate);
    }
}