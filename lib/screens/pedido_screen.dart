import 'package:flutter/material.dart';
import '../models/pedido_model.dart';

class PedidoScreen extends StatefulWidget {
  final Pedido pedido;

  // O construtor recebe exatamente o "pedido" selecionado
  const PedidoScreen({super.key, required this.pedido});

  @override
  _PedidoScreenState createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  // Mapa para guardar os controladores de texto de cada item e capturar as quantidades digitadas
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Inicializa um controlador de texto para cada produto da lista do pedido
    for (var item in widget.pedido.itens) {
      _controllers[item.descricao] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Limpa os controladores da memória ao fechar a tela para evitar vazamento de memória (Memory Leak)
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _salvarConferencia() {
    // Print operacional simulando o envio dos dados coletados de volta ao seu PHP
    _controllers.forEach((produto, controller) {
      print('Produto: $produto | Qtd Digitada: ${controller.text}');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Separação do pedido ${widget.pedido.numeroPedido} salva com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );

    // Retorna para a tela de listagem geral
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Pedido - ${widget.pedido.numeroPedido}'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 1. Cabeçalho Fixo com os Dados do Cliente atual
          Container(
            width: double.infinity,
            color: Colors.grey[100],
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pedido.cliente,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transportadora: ${widget.pedido.transportadora}', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('Data: ${widget.pedido.data}', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ],
            ),
          ),
          
          Divider(height: 1, thickness: 1),

          // 2. A listagem dinâmica de itens que você estava tentando encaixar!
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: widget.pedido.itens.length,
              itemBuilder: (context, index) {
                var item = widget.pedido.itens[index] as dynamic;
                
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Lado Esquerdo: Detalhes do Produto
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Localização Dinâmica vinda do banco de dados
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LOC: ${item.localizacao ?? "NÃO DEFINIDA"}',
                                style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              item.descricao,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            // Quantidade solicitada do produto vindo dinamicamente do banco
                            Text(
                              'Qtd Solicitada: ${item.qtd} ${item.um}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                        
                        SizedBox(width: 16),

                        // Lado Direito: Campo para preenchimento numérico da conferência
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _controllers[item.descricao],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Coletado',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Rodapé Fixo com os botões de ação (Voltar e Salvar)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: Colors.teal),
                    label: Text('VOLTAR', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.teal),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _salvarConferencia,
                    icon: Icon(Icons.check_circle, color: Colors.white),
                    label: Text('SALVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}