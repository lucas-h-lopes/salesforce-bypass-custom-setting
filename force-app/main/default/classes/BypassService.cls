public class BypassService {
   
    public static void updateWithBypass(List<SObject> sobj){
        BypassSettings__c bypass = BypassSettings__c.getValues(UserInfo.getUserId());

        handleBypassLogic(bypass, true);

        upsert sobj;
        
        bypass = BypassSettings__c.getValues(UserInfo.getUserId());
        handleBypassLogic(bypass, false);
    }

    private static void handleBypassLogic(BypassSettings__c bypass, Boolean isActive){
        if(bypass == null){
            insert new BypassSettings__c(Enabled__c=isActive, SetupOwnerId=UserInfo.getUserId());
            return;
        }

        if(bypass.Enabled__c != isActive){
            bypass.Enabled__c = isActive;
            update bypass;
        }
    }
}