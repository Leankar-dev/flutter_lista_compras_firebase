import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lista_compras_firebase/firestore_produtos/presentation/produto_screen.dart';
import 'package:uuid/uuid.dart';
import '../models/listin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Listin> listListins = [];
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    refresch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Center(child: const Text("Listin - Feira Colaborativa")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showFormModal();
        },
        child: const Icon(Icons.add),
      ),
      body: (listListins.isEmpty)
          ? const Center(
              child: Text(
                "Nenhuma lista ainda.\nVamos criar a primeira?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : RefreshIndicator(
              onRefresh: () {
                return refresch();
              },
              child: ListView(
                children: List.generate(listListins.length, (index) {
                  Listin model = listListins[index];
                  return Dismissible(
                    // key: Key(model.id),
                    key: ValueKey<Listin>(model),
                    onDismissed: (direction) {
                      // Remove o Listin do Firestore
                      remove(model);
                      // Exibe um SnackBar para informar que o Listin foi removido
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${model.name} removido com sucesso!"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      onLongPress: () {
                        showFormModal(model: model);
                      },
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProdutoScreen(listin: model),
                          ),
                        );
                      },
                      leading: const Icon(Icons.list_alt_rounded),
                      title: Text(model.name),
                      subtitle: Text(model.id),
                    ),
                  );
                }),
              ),
            ),
    );
  }

  showFormModal({Listin? model}) {
    // Labels à serem mostradas no Modal
    String title = "Adicionar Listin";
    String confirmationButton = "Salvar";
    String skipButton = "Cancelar";

    // Controlador do campo que receberá o nome do Listin
    TextEditingController nameController = TextEditingController();

    // Se o model não for nulo, significa que estamos editando um Listin existente
    if (model != null) {
      title = "Editando ${model.name}";
      confirmationButton = "Atualizar";
      skipButton = "Excluir";

      // Preenche o campo com o nome do Listin existente
      nameController.text = model.name;

      // Se o usuário clicar no botão de excluir, remove o Listin do Firestore
      skipButton = "Excluir";
      confirmationButton = "Atualizar";
    }

    // Função do Flutter que mostra o modal na tela
    showModalBottomSheet(
      context: context,

      // Define que as bordas verticais serão arredondadas
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(32.0),

          // Formulário com Título, Campo e Botões
          child: ListView(
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  label: Text("Nome do Listin"),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(skipButton),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Listin listin = Listin(
                        id: const Uuid().v1(),
                        name: nameController.text,
                      );

                      // Se o model não for nulo, significa que estamos editando um Listin existente
                      if (model != null) {
                        listin.id = model.id; // Mantém o ID do Listin existente
                      }
                      // Salva o Listin no Firestore
                      firestore
                          .collection('listins')
                          .doc(listin.id)
                          .set(listin.toMap());
                      refresch();
                      Navigator.pop(context);
                    },
                    child: Text(confirmationButton),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  refresch() async {
    List<Listin> list = [];
    QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('listins')
        .get();
    for (var doc in snapshot.docs) {
      list.add(Listin.fromMap(doc.data()));
    }
    setState(() {
      listListins = list;
    });
  }

  void remove(Listin model) {
    firestore.collection('listins').doc(model.id).delete();
    listListins.remove(model);
    setState(() {});
    refresch();
  }
}
