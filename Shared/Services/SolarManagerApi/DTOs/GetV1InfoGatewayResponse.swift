struct GetV1InfoGatewayResponse : Decodable {
    var gateway: GatewayInfo;
}

struct GatewayInfo : Decodable {
    var _id: String;
    var signal: String;
    var name: String;
    var sm_id: String;
}
