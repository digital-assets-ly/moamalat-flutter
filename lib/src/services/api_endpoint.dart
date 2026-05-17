enum ApiEndpoint {
  payByCard('/PayByCard'),
  checkTransactionStatus('/CheckTxnStatus');

  const ApiEndpoint(this.path);

  final String path;
}
