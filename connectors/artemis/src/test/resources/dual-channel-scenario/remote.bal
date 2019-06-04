import ballerina/http;
import ballerina/log;
import ballerinax/kubernetes;

@kubernetes:Ingress {
    hostname:"artemis.ballerina.io",
    name:"http-service",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"http-service"
}

@kubernetes:Deployment {
    image:"artemis.ballerina.io/http-service:v1.0",
    name:"http-service",
    username:"<USERNAME>",
    password:"<PASSWORD>",
    push:true,
    imagePullPolicy:"Always"
}

listener http:Listener helloListener = new(9090);
@http:ServiceConfig {
    basePath: "/"
}
service hello on helloListener {

    @http:ResourceConfig {
        path: "/remote",
        methods: ["POST"]
    }
    resource function sayHello(http:Caller caller, http:Request req) {
        json resp = {"hello": "Riyafa"};
        var result = caller->respond(resp);

        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}
