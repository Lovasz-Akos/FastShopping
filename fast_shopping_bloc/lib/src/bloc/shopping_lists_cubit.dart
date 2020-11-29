import 'package:bloc/bloc.dart';
import 'package:clock/clock.dart';
import 'package:fast_shopping_bloc/src/data/shopping_list_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/shopping_list.dart';

part 'shopping_lists_cubit.freezed.dart';

class ShoppingListsCubit extends Cubit<ShoppingListsState> {
  ShoppingListsCubit(this._repository, this._clock)
      : super(ShoppingListsState());

  final ShoppingListRepository _repository;
  final Clock _clock;

  @override
  void onChange(Change<ShoppingListsState> change) {
    super.onChange(change);

    _repository.saveSelectedListId(state.selectedId);
    _repository.saveLists(state.lists);
  }

  Future<void> load() async {
    final results = await Future.wait([
      _repository.getSelectedListId(),
      _repository.getLists(),
    ]);

    emit(ShoppingListsState(
      selectedId: results[0] as String,
      lists: results[1] as List<ShoppingList>,
    ));
  }

  void add(ShoppingList list) {
    emit(state.copyWith(lists: List.of(state.lists)..add(list)));
  }

  void update(ShoppingList list) {
    emit(state.copyWith(
      lists: state.lists
          .map((stateList) => stateList.id == list.id ? list : stateList)
          .toList(),
    ));
  }

  void select(String id) {
    if (state.lists.every((list) => list.id != id)) {
      throw Exception(
        'Shopping list with id $id is not on the shopping lists list.',
      );
    }

    emit(state.copyWith(selectedId: id));
  }

  void rename(String id, String newName) {
    emit(state.copyWith(
      lists: state.lists
          .map((list) => list.id == id ? list.copyWith(name: newName) : list)
          .toList(),
    ));
  }

  void archive(String id) {
    emit(state.copyWith(
      lists: state.lists
          .map((list) =>
              list.id == id ? list.copyWith(archivedAt: _clock.now()) : list)
          .toList(),
    ));
  }

  void unarchive(String id) {
    emit(state.copyWith(
      lists: state.lists
          .map((list) => list.id == id ? list.copyWith(archivedAt: null) : list)
          .toList(),
    ));
  }

  void remove(String id) {
    emit(state.copyWith(
      selectedId: id == state.selectedId ? null : state.selectedId,
      lists: List.of(state.lists)..removeWhere((list) => list.id == id),
    ));
  }
}

@freezed
abstract class ShoppingListsState implements _$ShoppingListsState {
  factory ShoppingListsState({
    String selectedId,
    @Default([]) List<ShoppingList> lists,
  }) = _ShoppingListsState;

  ShoppingListsState._();

  @late
  ShoppingList get selected => lists.firstWhere(
        (list) => list.id == selectedId,
        orElse: () => null,
      );

  @late
  List<ShoppingList> get current =>
      lists.where((list) => list.archivedAt == null).toList();

  @late
  List<ShoppingList> get archived =>
      lists.where((list) => list.archivedAt != null).toList();
}