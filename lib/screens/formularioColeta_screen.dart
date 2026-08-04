import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FormularioColetaScreen extends StatefulWidget {
  final int pedidoId;
  final String clienteNome;

  const FormularioColetaScreen({
    super.key, 
    required this.pedidoId, 
    required this.clienteNome,
  });

  @override
  _FormularioColetaScreenState createState() => _FormularioColetaScreenState();
}

class _FormularioColetaScreenState extends State<FormularioColetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();

  // Controlador do quadro de assinatura
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _enviando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _placaController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _finalizarColeta() async {
    // 1. Valida se os campos de texto foram preenchidos
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Valida se a assinatura foi feita
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, colete a assinatura do motorista.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      // 3. Converte a assinatura para imagem e depois para String Base64
      final assinaturaBytes = await _signatureController.toPngBytes();
      final assinaturaBase64 = base64Encode(assinaturaBytes!);

      // 4. Monta os dados para enviar ao PHP
      final payload = {
        "pedido_id": widget.pedidoId,
        "nome": _nomeController.text,
        "documento": _documentoController.text,
        "placa_veiculo": _placaController.text,
        "assinatura": 'data:image/png;base64,$assinaturaBase64'
      };

      // TODO: Ajuste o IP para sua rede local
      final url = Uri.parse('http://192.168.X.X/expedicao_db/salvar_coleta.php');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final resultado = json.decode(response.body);
        if (resultado['sucesso'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coleta registrada com sucesso!'), backgroundColor: Colors.green),
          );
          
          // O pedido agora está "coletado = 1", então fechamos esta tela
          // e podemos até fechar a tela anterior para forçar um refresh visual
          Navigator.of(context).pop(true); 
        } else {
          _mostrarErro(resultado['mensagem'] ?? 'Erro ao salvar no banco.');
        }
      } else {
        _mostrarErro('Erro no servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro de conexão. Verifique a rede.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro', style: TextStyle(color: Colors.red)),
        content: Text(mensagem),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Coleta'),
        backgroundColor: Colors.teal,
      ),
      body: _enviando
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho de identificação
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pedido: #${widget.pedidoId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Cliente: ${widget.clienteNome}', style: TextStyle(color: Colors.teal[800])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Formulário do Motorista
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Motorista',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _documentoController,
                      decoration: const InputDecoration(
                        labelText: 'Documento (RG/CPF/CNH)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _placaController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Placa do Veículo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 24),

                    // Área de Assinatura
                    const Text(
                      'Assinatura do Motorista:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Signature(
                        controller: _signatureController,
                        height: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    
                    // Botão para limpar a assinatura caso o motorista erre
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _signatureController.clear(),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpar Assinatura'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botão de Salvar
                    ElevatedButton.icon(
                      onPressed: _finalizarColeta,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text('FINALIZAR COLETA', style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}