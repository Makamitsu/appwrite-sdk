class_name DatabaseTask
extends RefCounted

signal completed(task_response)

enum Task {
	# Server
	CREATE_COLLECTION,
	LIST_COLLECTIONS,
	GET_COLLECTION,
	UPDATE_COLLECTION,
	DELETE_COLLECTION,
	# Client
	CREATE_DOCUMENT,
	LIST_DOCUMENTS,
	GET_DOCUMENT,
	UPDATE_DOCUMENT,
	DELETE_DOCUMENT
}

var _code : int
var _method : int
var _endpoint : String
var _headers : PackedStringArray
var _payload : Dictionary

# EXPOSED VARIABLES ---------------------------------------------------------
var response : Dictionary
var error : Dictionary
# ---------------------------------------------------------------------------

var _handler : HTTPRequest

func _init(code : int, endpoint : String, headers : PackedStringArray,  payload : Dictionary = {}):
	_code = code
	_endpoint = endpoint
	_headers = headers
	_payload = payload
	_method = match_code(code)


func match_code(code : int) -> int:
	match code:
		Task.CREATE_COLLECTION, Task.CREATE_DOCUMENT:
			return HTTPClient.METHOD_POST
		Task.DELETE_COLLECTION, Task.DELETE_DOCUMENT:
			return HTTPClient.METHOD_DELETE
		Task.UPDATE_COLLECTION: 
			return HTTPClient.METHOD_PUT
		Task.UPDATE_DOCUMENT:
			return HTTPClient.METHOD_PATCH
		_: return HTTPClient.METHOD_GET

func push_request(httprequest : HTTPRequest) -> void:
	_handler = httprequest
	httprequest.request_completed.connect(self._on_task_completed)
	httprequest.request(_endpoint, _headers, _method, JSON.stringify(_payload) if not _payload.size()==0 else "")

func _on_task_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	if result > 0: 
		complete({}, {result = result, message = "HTTP Request Error"})
		return
	var result_body = JSON.parse_string(body.get_string_from_utf8()).result if body.get_string_from_utf8() else {}
	if response_code in [200, 201, 204]:
		complete(result_body)
	else:
		complete({}, result_body)

func complete(_result: Dictionary,  _error : Dictionary = {}) -> void:
	response = _result
	error = _error
	if _handler : _handler.queue_free()
	emit_signal("completed", TaskResponse.new(response, error))
