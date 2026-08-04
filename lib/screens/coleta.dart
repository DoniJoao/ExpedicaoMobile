import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// -----------------------------------------------------------------------------
// MODELO DE DADOS: Representa uma Coleta/Faturamento do Banco de Dados
// -----------------------------------------------------------------------------
class Coleta {
  final String id;
  final String empresa;
  final String retiradoPor;
  final String documento;
  final String placa;
  final String data;
  final String assinaturaBase64; // A string gigante que vem do banco

  Coleta({
    required this.id,
    required this.empresa,
    required this.retiradoPor,
    required this.documento,
    required this.placa,
    required this.data,
    required this.assinaturaBase64,
  });

  factory Coleta.fromJson(Map<String, dynamic> json) {
    return Coleta(
      id: json['id']?.toString() ?? '',
      empresa: json['empresa']?.toString() ?? '',
      retiradoPor: json['retirado_por']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      placa: json['placa']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
      assinaturaBase64: json['assinatura_base64']?.toString() ?? '',
    );
  }
}

// -----------------------------------------------------------------------------
// TELA PRINCIPAL
// -----------------------------------------------------------------------------
class AssinaturasScreen extends StatefulWidget {
  const AssinaturasScreen({super.key});

  @override
  _AssinaturasScreenState createState() => _AssinaturasScreenState();
}

class _AssinaturasScreenState extends State<AssinaturasScreen> {
  List<Coleta> coletas = [];
  bool carregando = true;
  String? erroMensagem;

  // Controladores para o formulário de filtros (Igual ao seu HTML)
  final TextEditingController _buscaController = TextEditingController();
  String _statusSelecionado = 'faturado'; // Padrão selecionado no seu HTML

  @override
  void initState() {
    super.initState();
    buscarColetasDoBanco();
  }

  // Função para buscar dados da API PHP
  Future<void> buscarColetasDoBanco() async {
    setState(() {
      carregando = true;
      erroMensagem = null;
    });

    // Envia os filtros via parâmetros GET, exatamente como o formulário HTML faz
    final queryParameters = {
      'busca': _buscaController.text,
      'status': _statusSelecionado,
    };

    // Altere para o IP do seu servidor Windows local
    final uri = Uri.http(
      'localhost', 
      '/expedicao_db/obter_assinaturas.php', 
      queryParameters
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> dadosJson = json.decode(utf8.decode(response.bodyBytes));
        
        setState(() {
          coletas = dadosJson.map((json) => Coleta.fromJson(json)).toList();
          carregando = false;
        });
      } else {
        setState(() {
          erroMensagem = 'Erro no servidor: ${response.statusCode}';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        erroMensagem = 'Falha ao conectar na API local. Verifique sua rede.';
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definindo a cor 'Seashell' do seu CSS: background: seashell (FFF5EE)
    const corSeashell = Color(0xFFFFF5EE);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinaturas de Coleta', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 1. ÁREA DE FILTROS (Baseada no seu formulário HTML)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _buscaController,
                        decoration: InputDecoration(
                          labelText: 'Pesquisar (Pedido, Cliente, NF ou Placa)',
                          labelStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: _buscaController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _buscaController.clear();
                                    buscarColetasDoBanco();
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (_) => buscarColetasDoBanco(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: buscarColetasDoBanco,
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Seletor de Status (Pendente / Faturado) igual ao seu Radio Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Radio<String>(
                      value: 'pendente',
                      groupValue: _statusSelecionado,
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setState(() {
                          _statusSelecionado = value!;
                        });
                        buscarColetasDoBanco();
                      },
                    ),
                    const Text('Pendente', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 15),
                    Radio<String>(
                      value: 'faturado',
                      groupValue: _statusSelecionado,
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setState(() {
                          _statusSelecionado = value!;
                        });
                        buscarColetasDoBanco();
                      },
                    ),
                    const Text('Faturado', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // Faixa Informativa Teal indicando a quantidade encontrada
          Container(
            width: double.infinity,
            color: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Coletas Encontradas (${coletas.length})',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),

          // 2. CORPO DA TELA (Lista de Coletas)
          Expanded(
            child: _construirCorpo(corSeashell),
          ),
        ],
      ),
    );
  }

  Widget _construirCorpo(Color backgroundCard) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (erroMensagem != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(erroMensagem!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: buscarColetasDoBanco, child: const Text('Tentar Novamente'))
          ],
        ),
      );
    }

    if (coletas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma assinatura ou coleta localizada com estes filtros.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: coletas.length,
      itemBuilder: (context, index) {
        final coleta = coletas[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundCard, // Seashell background
            border: Border.all(color: Colors.teal, width: 1.2), // Teal border
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do Card (ID do Pedido e Empresa)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido Interno: #${coleta.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      coleta.empresa.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.teal, thickness: 0.5),
              const SizedBox(height: 4),

              // Conteúdo Principal dividido em: Esquerda (Dados) / Direita (Assinatura)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dados da Retirada
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextRich('Retirado por: ', coleta.retiradoPor),
                        const SizedBox(height: 4),
                        _buildTextRich('Documento: ', coleta.documento),
                        const SizedBox(height: 4),
                        _buildTextRich('Placa: ', coleta.placa),
                        const SizedBox(height: 4),
                        _buildTextRich('Data: ', coleta.data),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Bloco de renderização da Imagem Base64 (Assinatura)
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: _renderizarAssinatura(coleta.assinaturaBase64),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Função auxiliar para criar textos com partes sublinhadas (igual ao seu HTML)
  Widget _buildTextRich(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 12.5),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: value.isNotEmpty ? value : 'Não informado',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  // Função Mágica que decodifica o Base64 e desenha a assinatura na tela
  Widget _renderizarAssinatura(String base64String) {
    if (base64String.isEmpty) {
      return const Icon(Icons.gesture, color: Colors.grey, size: 30);
    }

    try {
      // Limpa os prefixos comuns como "data:image/png;base64," e quebras de linha que quebram o parser do Flutter
      final stringLimpa = base64String
          .replaceFirst(RegExp(r'data:image\/[a-zA-Z]+;base64,'), '')
          .replaceAll('\n', '')
          .trim();

      // Transforma a String limpa em uma lista de bytes
      final bytes = base64Decode(stringLimpa);

      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Se o banco retornar um base64 corrompido
          return const Icon(Icons.broken_image, color: Colors.red, size: 24);
        },
      );
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.red, size: 24);
    }
  }
}