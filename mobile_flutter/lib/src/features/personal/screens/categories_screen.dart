import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/personal_finance_controller.dart';
import '../models/personal_category.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  Future<void> _showCategoryForm(
    BuildContext context,
    PersonalFinanceController controller, {
    String? categoryId,
    String? currentName,
    TipoTransacao? currentTipo,
    IconData? currentIcon,
    Color? currentColor,
  }) async {
    final nameController = TextEditingController(text: currentName);
    TipoTransacao tipo = currentTipo ?? TipoTransacao.despesa;
    IconData selectedIcon = currentIcon ?? Icons.attach_money;
    Color selectedColor = currentColor ?? AppTheme.primary;
    final formKey = GlobalKey<FormState>();

    final availableIcons = [
      Icons.attach_money,
      Icons.shopping_cart,
      Icons.restaurant,
      Icons.local_gas_station,
      Icons.home,
      Icons.directions_car,
      Icons.phone_android,
      Icons.local_hospital,
      Icons.school,
      Icons.fitness_center,
      Icons.movie,
      Icons.flight,
      Icons.pets,
      Icons.shopping_bag,
      Icons.credit_card,
    ];

    final availableColors = [
      AppTheme.primary,
      AppTheme.accent,
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            categoryId == null ? 'Nova Categoria' : 'Editar Categoria',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da categoria',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (categoryId == null)
                    SegmentedButton<TipoTransacao>(
                      segments: const [
                        ButtonSegment(
                          value: TipoTransacao.receita,
                          label: Text('Receita'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: TipoTransacao.despesa,
                          label: Text('Despesa'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {tipo},
                      onSelectionChanged: (value) {
                        setState(() {
                          tipo = value.first;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  const Text('Ícone:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableIcons.map((icon) {
                      final isSelected = icon == selectedIcon;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Cor:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableColors.map((color) {
                      final isSelected = color == selectedColor;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final nome = nameController.text.trim();

      if (categoryId == null) {
        await controller.createCategory(
          nome: nome,
          tipo: tipo,
          iconeCodePoint: selectedIcon.codePoint,
          corValue: selectedColor.value,
        );
      } else {
        await controller.updateCategory(
          categoryId: categoryId,
          nome: nome,
          iconeCodePoint: selectedIcon.codePoint,
          corValue: selectedColor.value,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              categoryId == null
                  ? 'Categoria criada com sucesso'
                  : 'Categoria atualizada com sucesso',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    PersonalFinanceController controller,
    String categoryId,
    String categoryName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text(
          'Deseja realmente excluir a categoria "$categoryName"?\n\n'
          'Não é possível excluir categorias com transações vinculadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await controller.deleteCategory(categoryId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria excluída com sucesso')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categorias'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Receitas', icon: Icon(Icons.arrow_upward)),
              Tab(text: 'Despesas', icon: Icon(Icons.arrow_downward)),
            ],
          ),
        ),
        body: Consumer<PersonalFinanceController>(
          builder: (context, controller, _) {
            final receitas = controller.getCategoriesByType(TipoTransacao.receita);
            final despesas = controller.getCategoriesByType(TipoTransacao.despesa);

            return TabBarView(
              children: [
                _buildCategoryList(context, controller, receitas),
                _buildCategoryList(context, controller, despesas),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final controller = context.read<PersonalFinanceController>();
            _showCategoryForm(context, controller);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nova Categoria'),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    PersonalFinanceController controller,
    List<PersonalCategory> categories,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma categoria cadastrada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.cor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icone, color: category.cor),
            ),
            title: Text(
              category.nome,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              category.tipo == TipoTransacao.receita ? 'Receita' : 'Despesa',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showCategoryForm(
                    context,
                    controller,
                    categoryId: category.id,
                    currentName: category.nome,
                    currentTipo: category.tipo,
                    currentIcon: category.icone,
                    currentColor: category.cor,
                  );
                } else if (value == 'delete') {
                  _deleteCategory(
                    context,
                    controller,
                    category.id,
                    category.nome,
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
