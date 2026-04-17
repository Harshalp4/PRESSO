class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<String>? errors;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String message, {int? statusCode, List<String>? errors}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  bool get isSuccess => success;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
    );
  }

  bool get hasErrors => errors != null && errors!.isNotEmpty;

  String get errorMessage =>
      errors?.isNotEmpty == true ? errors!.first : (message ?? 'Unknown error');

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, data: $data, errors: $errors)';
}

class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawItems = json['items'] as List? ?? [];
    return PaginatedResponse(
      items: rawItems
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
    );
  }

  bool get hasMore => page * pageSize < totalCount;

  int get totalPages => (totalCount / pageSize).ceil();

  bool get isLastPage => page >= totalPages;

  @override
  String toString() =>
      'PaginatedResponse(items: ${items.length}, totalCount: $totalCount, page: $page, pageSize: $pageSize)';
}
