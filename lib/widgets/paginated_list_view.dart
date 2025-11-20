import 'package:flutter/material.dart';

class PaginatedListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) fetchData;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int pageSize;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final bool enableLazyLoading;

  const PaginatedListView({
    super.key,
    required this.fetchData,
    required this.itemBuilder,
    this.pageSize = 20,
    this.emptyWidget,
    this.errorWidget,
    this.enableLazyLoading = true,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.enableLazyLoading) {
      _loadMore();
    } else {
      // Load all data at once if lazy loading is disabled
      _loadAllData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.enableLazyLoading &&
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore || !widget.enableLazyLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.fetchData(_currentPage, widget.pageSize);
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    });
    if (widget.enableLazyLoading) {
      await _loadMore();
    } else {
      await _loadAllData();
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all pages until no more data
      while (_hasMore) {
        final newItems = await widget.fetchData(_currentPage, widget.pageSize);
        if (newItems.isEmpty) {
          _hasMore = false;
          break;
        }
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.pageSize;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ??
          const Center(child: Text('No items found'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_isLoading && widget.enableLazyLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length && widget.enableLazyLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
}
