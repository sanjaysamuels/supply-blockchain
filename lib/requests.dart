import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final server = SorobanServer("https://soroban-testnet.stellar.org");

Future<void> getHealth() async {
  String accountId = "GAHYPUZ6BZZ6UYSM4KFP3CO2MJBFA36LOP6V4QME5WIKHW5E77QMLHHV";
  final healthResponse = await server.getHealth();

  if (GetHealthResponse.HEALTHY == healthResponse.status) {
    print("Server is healthy");
  }

  final account = await server.getAccount(accountId);
  print("Sequence: ${account!.sequenceNumber}");
}

Future<void> invokeIncrementContract() async {
  try {
    // 1. Create a SorobanServer instance pointing to testnet
    final sorobanServer = SorobanServer("https://soroban-testnet.stellar.org");

    // 2. Set up your contract and account details
    final contractId =
        "CBW53NNUEFB5DQ2HUTVHNKWWEPWEZB42LCMNBZDXEOTZ4F55YSTTCJ7L";

    // 3. You need your secret key here - it should be stored securely
    // If you created the account with `stellar keys generate --global alice --network testnet --fund`,
    // the secret key is stored in: ~/.config/stellar/identity/alice.toml
    // You can get it with: `stellar keys show alice`

    final secretSeed =
        "SB2L747QVOAMPLH6LRAF7IUIZEXOFWP47OHTPP3XHCEVJSYINAANL3R6";

    final sourceAccountKeyPair = KeyPair.fromSecretSeed(secretSeed);
    final client = await SorobanClient.forClientOptions(
      options: ClientOptions(
        sourceAccountKeyPair: sourceAccountKeyPair,
        contractId: contractId,
        network: Network.TESTNET,
        rpcUrl: "https://soroban-testnet.stellar.org",
      ),
    );

    final result = await client.invokeMethod(
      name: "increment",
      args: [], // The increment method doesn't need any arguments
    );

    // Extract the value based on the XdrSCVal type
    int? counterValue;

    switch (result.discriminant) {
      case XdrSCValType.SCV_U32:
        // For u32, get the value from the XdrUint32 object
        counterValue = result.u32?.uint32;
        break;
      case XdrSCValType.SCV_I32:
        // For i32, get the value from the XdrInt32 object
        counterValue = result.i32?.int32;
        break;
      case XdrSCValType.SCV_U64:
        // For u64, get the value from the XdrUint64 object
        counterValue = result.u64?.uint64;
        break;
      case XdrSCValType.SCV_I64:
        // For i64, get the value from the XdrInt64 object
        counterValue = result.i64?.int64;
        break;
      default:
        print("Unexpected result type: ${result.discriminant}");
    }

    if (counterValue != null) {
      print("Contract invoked successfully!");
      print("New counter value: $counterValue");
    } else {
      print("Could not extract counter value. Type: ${result.discriminant}");
      // Debug - Print all potential value fields
      print("Debug info:");
      if (result.u32 != null) print("u32: ${result.u32?.uint32}");
      if (result.i32 != null) print("i32: ${result.i32?.int32}");
      if (result.u64 != null) print("u64: ${result.u64?.uint64}");
      if (result.i64 != null) print("i64: ${result.i64?.int64}");
    }
  } catch (e) {
    print("Error: $e");
  }
}
