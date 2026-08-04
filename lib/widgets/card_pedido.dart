import 'package:flutter/material.dart';
import '../models/pedidos.dart';
import '../screens/pedido.dart'; // Import crucial para o Flutter saber para onde ir

class CardPedido extends StatelessWidget {
  final Pedido pedido;

  const CardPedido({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    // O InkWell adiciona o efeito visual de clique e a ação do "onTap"
    return InkWell(
      onTap: () {
        // ESSA É A AÇÃO QUE ABRE A TELA DO PEDIDO ao clicar em qualquer lugar do Card
        
        Navigator.of(context).push(
          MaterialPageRoute(
           builder: (context) => PedidoScreen(pedido: pedido), 
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFFFF5EE), // seashell
          border: Border.all(color: Colors.teal, width: 1),
          borderRadius: BorderRadius.circular(4), // Deixa os cantos levemente arredondados
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha do Cliente
            Row(
              children: [
                Icon(Icons.business, color: Colors.teal), 
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pedido.cliente,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Dados do pedido
            Text(
              'Pedido: ${pedido.numeroPedido}  |  Data: ${pedido.data}  |  Valor: R\$ ${pedido.valor.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            SizedBox(height: 8),
            
            // Faixa da Transportadora
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(6),
              color: Colors.teal,
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Transp: ${pedido.transportadora}', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),

            // NOVO: Bloco de Instruções de Faturamento (Direto na tela, sem modal)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple[50], // Um fundo sutil roxo para destacar
                border: Border.all(color: Colors.purple[200]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: Colors.purple[700], size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Instruções de Faturamento:', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[900], fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    // Se a observação/instrução vier nula da API, ele mostra um texto padrão
                    pedido.observacao ?? 'Nenhuma instrução cadastrada para este pedido.',
                    style: TextStyle(fontSize: 13, color: Colors.purple[900], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            
            // Listagem rápida dos itens
            Text('Itens:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ...pedido.itens.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                '${item.qtd}x  [${item.um}]  - ${item.descricao}',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            )),
          ],
        ),
      ),
    );
  }
}