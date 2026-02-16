enum WhereOperation {
  equal,
  notEqual,
  less,
  lessOrEqual,
  greater,
  greaterOrEqual,
  between;

  static String operatorToString(WhereOperation operation) {
    switch (operation) {
      case WhereOperation.equal:
        return "=";
      case WhereOperation.notEqual:
        return "!=";
      case WhereOperation.less:
        return "<";
      case WhereOperation.lessOrEqual:
        return "<=";
      case WhereOperation.greater:
        return ">";
      case WhereOperation.greaterOrEqual:
        return ">=";
      case WhereOperation.between:
        return "BETWEEN";
    }
  }
}

enum WhereChain {
  and,
  or;

  static String operatorToString(WhereChain operation) {
    switch (operation) {
      case WhereChain.and:
        return "AND";
      case WhereChain.or:
        return "OR";
    }
  }
}

class DBWhere {
  String column;
  WhereOperation operation;
  dynamic value;
  WhereChain? chain;

  DBWhere({
    required this.column,
    required this.operation,
    required this.value,
    this.chain,
  });

  @override
  String toString() {
    if (operation == WhereOperation.between) {
      return "$column ${WhereOperation.operatorToString(operation)} ? AND ? ";
    } else {
      return "$column ${WhereOperation.operatorToString(operation)} ? ";
    }
  }
}
