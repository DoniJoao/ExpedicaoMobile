  class Pedido {
    final String id;
    final String empresa;
    final String cliente;
    final String numeroPedido;
    final String data;
    final double valor;
    final String transportadora;
    final List<ItemPedido> itens;
    final String? observacao;

    Pedido({  
      required this.id,
      required this.empresa,
      required this.cliente,
      required this.numeroPedido,
      required this.data,
      required this.valor,
      required this.transportadora,
      required this.itens,
      this.observacao,
    });

    // Transforma o mapa do JSON vindo do PHP em um objeto Pedido do Flutter
    factory Pedido.fromJson(Map<String, dynamic> json) {
      var list = json['itens'] as List;
      List<ItemPedido> listaItens = list.map((i) => ItemPedido.fromJson(i)).toList();

      return Pedido(
        id: json['id'].toString(),
        empresa: json['empresa'] ?? '',
        cliente: json['cliente'] ?? '',
        numeroPedido: json['numeroPedido'] ?? '',
        data: json['data'] ?? '',
        valor: double.tryParse(json['valor'].toString()) ?? 0.0,
        transportadora: json['transportadora'] ?? '',
        observacao: json['observacao'],
        itens: listaItens,
      );
    }
  }

  class ItemPedido {
  final int qtd;
  final String um;
  final String descricao;
  final String? codigo;       
  final String? localizacao;    // Verifique se esta linha existe!
  final String? loteSelecionado; // Verifique se esta linha existe!
  final List<String> lotesDisponiveis;

  ItemPedido({
    required this.qtd,
    required this.um,
    required this.descricao,
    this.codigo,              
    this.localizacao,           
    this.loteSelecionado,      
    this.lotesDisponiveis = const [],
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    var lotesDoJson = json['lotes_disponiveis'] as List? ?? [];
    List<String> listaLotes = lotesDoJson.map((l) => l.toString()).toList();

    return ItemPedido(
      qtd: int.tryParse(json['qtd'].toString()) ?? 0,
      um: json['um'] ?? '',
      descricao: json['descricao'] ?? '',
      codigo: json['codigo']?.toString(),           
      localizacao: json['localizacao']?.toString(), // Mapeamento do banco
      loteSelecionado: json['lote']?.toString(),
      lotesDisponiveis: listaLotes.isEmpty && json['lote'] != null 
          ? [json['lote'].toString()] 
          : listaLotes,
    );
  }
}