package aws;

typedef StackRequestBase = {
    ?Capabilities:Array<String>,
    ?ClientRequestToken:String,
    ?NotificationARNs:Array<String>,
    ?Parameters:Array<{
        ?ParameterKey:String,
        ?ParameterValue:String,
        ?ResolvedValue:String
    }>,
    ?ResourceTypes:Array<String>,
    ?RoleARN:String,
    ?RollbackConfiguration:{
        ?MonitoringTimeInMinutes:Int,
        ?RollbackTriggers:Array<{
            Arn:String,
            Type:String
        }>,
    },
    StackName:String,
    ?StackPolicyBody:String,
    ?StackPolicyURL:String,
    ?Tags:Array<{
        Key:String,
        Value:String
    }>,
    ?TemplateBody:String,
    ?TemplateURL:String,
}

typedef CreateStackRequestData = { > StackRequestBase,
    ?DisableRollback:Bool,
    ?EnableTerminationProtection:Bool,
    ?OnFailure:String,
    ?ResourceTypes:Array<String>,
    ?TimeoutInMinutes:Int
}

typedef UpdateStackRequestData = { > StackRequestBase,
    ?StackPolicyDuringUpdateBody:String,
    ?StackPolicyDuringUpdateURL:String,
    ?UsePreviousTemplate:Bool
}