import 'package:flutter/material.dart';

class LazyGridView<T> extends StatefulWidget {
  final Future<List<T>> Function(int offset, int limit) loadItems;
  final Widget Function(T item, int index) itemBuilder;
  final int itemsPerPage;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets padding;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const LazyGridView({
    super.key,
    required this.loadItems,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.padding = const EdgeInsets.all(16.0),
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<LazyGridView<T>> createState() => _LazyGridViewState<T>();
}

class _LazyGridViewState<T> extends State<LazyGridView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _loadInitialItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final newItems = await widget.loadItems(0, widget.itemsPerPage);
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = newItems.length == widget.itemsPerPage;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final offset = _currentPage * widget.itemsPerPage;
      final newItems = await widget.loadItems(offset, widget.itemsPerPage);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = newItems.length == widget.itemsPerPage;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refresh() async {
    await _loadInitialItems();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Terjadi kesalahan'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialItems,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Text('Tidak ada data'),
          );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
          childAspectRatio: 0.75,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return widget.itemBuilder(_items[index], index);
        },
      ),
    );
  }
}

// Optimized list view for activities
class LazyListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int offset, int limit) loadItems;
  final Widget Function(T item, int index) itemBuilder;
  final int itemsPerPage;
  final EdgeInsets padding;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const LazyListView({
    super.key,
    required this.loadItems,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.padding = const EdgeInsets.all(16.0),
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<LazyListView<T>> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _loadInitialItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final newItems = await widget.loadItems(0, widget.itemsPerPage);
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = newItems.length == widget.itemsPerPage;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final offset = _currentPage * widget.itemsPerPage;
      final newItems = await widget.loadItems(offset, widget.itemsPerPage);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = newItems.length == widget.itemsPerPage;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refresh() async {
    await _loadInitialItems();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Terjadi kesalahan'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialItems,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Text('Tidak ada data'),
          );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return widget.itemBuilder(_items[index], index);
        },
      ),
    );
  }
}
