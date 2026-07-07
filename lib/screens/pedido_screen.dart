import 'package:flutter/material.dart';
import '../models/pedido_model.dart';

class PedidoScreen extends StatefulWidget {
  final Pedido pedido;

  const PedidoScreen({super.key, required this.pedido});

  @override
  _PedidoScreenState createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  // Chave baseada em "codigo_lote" para individualizar cada input de lote da tela
  final Map<String, TextEditingController> _controllers = {};
  // Controlador dedicado para a quantidade global de volumes do pedido
  final TextEditingController _volumesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Inicializa os controladores dos produtos e lotes
    for (var item in widget.pedido.itens) {
      final lotes = (item.lote == null)
          ? <String>[]
          : item.lote!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      for (var loteOpcao in lotes) {
        final chaveUnica = '${item.codigo ?? ""}_$loteOpcao';
        _controllers[chaveUnica] = TextEditingController();

        // Se este lote for o sugerido inicialmente pelo ERP, pré-preenche
        if (item.lote == loteOpcao) {
          _controllers[chaveUnica]!.text = item.qtd.toString();
        }
      }
    }
    // Inicializa o campo de volumes com o valor padrão sugerido
    _volumesController.text = '1'; 
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _volumesController.dispose();
    super.dispose();
  }

  void _salvarConferencia() {
    List<String> erros = [];
    print('--- INICIANDO VALIDAÇÃO COMPLETA DA CONFERÊNCIA ---');
    
    // 1. Validação dos Volumes Finais Globais
    final int qtdVolumes = int.tryParse(_volumesController.text) ?? 0;
    if (qtdVolumes <= 0) {
      erros.add('A quantidade de volumes do pedido deve ser maior que zero.');
    }

    // 2. Validação Consolidada: Agrupa o que foi digitado por produto para comparar com o Pedido
    for (var item in widget.pedido.itens) {
      int somaColetadaProduto = 0;

      final lotes = (item.lote == null)
          ? <String>[]
          : item.lote!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      for (var loteOpcao in lotes) {
        final chaveUnica = '${item.codigo ?? ""}_$loteOpcao';
        final int qtdDigitadaNoLote = int.tryParse(_controllers[chaveUnica]?.text ?? '') ?? 0;
        somaColetadaProduto += qtdDigitadaNoLote;
      }

      final int qtdEsperada = item.qtd;

      // Trava de segurança: impede que a soma dos lotes seja diferente da do pedido
      if (somaColetadaProduto < qtdEsperada) {
        erros.add('${item.descricao}: Falta coletar ${qtdEsperada - somaColetadaProduto} ${item.um} (Soma dos lotes: $somaColetadaProduto/$qtdEsperada).');
      } else if (somaColetadaProduto > qtdEsperada) {
        erros.add('${item.descricao}: Quantidade acima do pedido em ${somaColetadaProduto - qtdEsperada} ${item.um} (Soma dos lotes: $somaColetadaProduto/$qtdEsperada).');
      }
    }

    // Se houver qualquer erro (seja de volume ou de lotes), bloqueia o salvamento e exibe o pop-up
    if (erros.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[800]),
              SizedBox(width: 10),
              Text('Atenção na Conferência', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Não é possível salvar. Corrija as inconsistências apontadas:', 
                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])
                ),
                SizedBox(height: 12),
                ...erros.map((erro) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('• $erro', style: TextStyle(color: Colors.red[700], fontSize: 14)),
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('REVISAR QUANTIDADES', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return; // Interrompe o envio para o PHP
    }

    // SUCESSO: Tudo bateu certinho! Pronto para mandar pro banco
    print('--- SUCESSO: DADOS 100% CORRETOS ---');
    print('Volumes Totais Fechados: $qtdVolumes');
    for (var item in widget.pedido.itens) {
      final lotes = (item.lote == null)
          ? <String>[]
          : item.lote!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      for (var loteOpcao in lotes) {
        final chaveUnica = '${item.codigo ?? ""}_$loteOpcao';
        final qtd = _controllers[chaveUnica]?.text ?? '0';
        if (int.parse(qtd) > 0) {
          print('Enviar para o PHP -> Cód: ${item.codigo} | Lote: $loteOpcao | Qtd Coletada: $qtd');
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido ${widget.pedido.numeroPedido} conferido com $qtdVolumes vol. Salvo com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(); // Retorna para a listagem
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
          // 1. CABEÇALHO FIXO (Dados do Cliente e Transportadora)
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

          // 2. LISTAGEM EM CASCATA DE LOTES AGRUPADOS POR PRODUTO (Igual ao seu HTML)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: widget.pedido.itens.length,
              itemBuilder: (context, index) {
                final item = widget.pedido.itens[index];
                
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabeçalho Centralizado do Produto (Equivalente ao <div class="text-center">)
                        Center(
                          child: Column(
                            children: [
                              Text(
                                item.descricao.toUpperCase(),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Código: ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                  Text('${item.codigo ?? "---"}', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Quantidade no Pedido: ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                  Text(
                                    '${item.qtd} ${item.um}', 
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                                  ),
                                ],
                              ),
                              if (item.localizacao != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  'LOC: ${item.localizacao}',
                                  style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),

                        // Subtítulo da Seção de Lotes
                        Text(
                          'Distribuição por Lotes:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),

                        // Renderiza a lista vertical de inputs para cada lote do produto
                        Column(
                          children: ((item.lote == null)
                                      ? <String>[]
                                      : item.lote!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList())
                                  .map<Widget>((loteOpcao) {
                            final chaveUnica = '${item.codigo ?? ""}_$loteOpcao';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  // Identificador do Lote (Equivalente ao <span class="re">26Q01408: </span>)
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Icon(Icons.layers, size: 16, color: Colors.blue[700]),
                                        SizedBox(width: 6),
                                        Text(
                                          '$loteOpcao:',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[800]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Campo de Digitação da Quantidade (Equivalente ao <input class="lote">)
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 40,
                                      child: TextField(
                                        controller: _controllers[chaveUnica],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText: 'Max: 50',
                                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                          contentPadding: EdgeInsets.zero,
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.blue, width: 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. SECTOR GLOBAL: Volumes Finais da Carga (Antes dos botões)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.teal[700]),
                    SizedBox(width: 8),
                    Text(
                      'Volumes Finais da Carga:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal[900]),
                    ),
                  ],
                ),
                SizedBox(
                  width: 100,
                  height: 45,
                  child: TextField(
                    controller: _volumesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. RODAPÉ FIXO (Botões Operacionais)
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