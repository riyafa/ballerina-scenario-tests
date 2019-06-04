import ballerina/artemis;
import ballerina/filepath;
import ballerina/http;
import ballerina/system;
import ballerinax/kubernetes;

artemis:Connection con = new("tcp://artemis-service:61616");
artemis:Session session = new(con, config = {username: "artemis", password: "simetraehcapa"});

@kubernetes:Ingress {
    hostname:"artemis.ballerina.io",
    name:"artemis-sender",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"artemis-sender"
}

@kubernetes:Deployment {
    image:"artemis.ballerina.io/artemis-sender:v1.0",
    name:"artemis-sender",
    username:"<USERNAME>",
    password:"<PASSWORD>",
    push:true,
    imagePullPolicy:"Always"
}

listener http:Listener sendListener = new(8080);

@http:ServiceConfig {
    basePath: "/artemis"
}
service SMSSenderProxy on sendListener {
    @http:ResourceConfig {
        path: "/test",
        methods: ["POST"]
    }
    resource function send(http:Caller caller, http:Request request) returns error? {
        artemis:Producer forwardProd = new(session, "SMSStore");

        artemis:Message msg = new(session, untaint check request.getJsonPayload(), 
        config = {replyTo: "SMSReceiveNotificationStore"});
        string id = system:uuid();
        msg.putProperty("UUID", id);
        check forwardProd->send(msg);

        string filter = "JMSCorrelationID = '" + id + "'";
        artemis:Listener qListener = new(session);
        artemis:Consumer consumer = check qListener.createAndGetConsumer({
            queueName: "SMSReceiveNotificationStore"
        }, autoAck = true, filter = filter);

        msg = check consumer->receive(timeoutInMilliSeconds = 3000);
        var payload = msg.getPayload();
        if (payload is json) {
            check caller->respond(untaint payload);
        }

    }
}
