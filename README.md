# hknife

It's a client http library and inspired by sinatra.
Focus on simpler and understand easily what request will be send from the code.
Notice it's super alpha quality and stability of interface.

# How to use

## Sending get request

```ruby
get('http://www.example.com').send
```

## Sending get request and post request with reponse of previous get request

```ruby
res = get('http://www.example.com').response
post_form('http://www.example.com/', id: res.body['id]).response
```

## Sending get request with customer header

```ruby
get('http://93.184.216.34/').
  header(Host: 'www.example.com').
  send
```

## Sending request asynchronously

```ruby
get("http://www.example.com/request1").async do |res|
  puts res.body
end

get("http://www.example.com/request2").async do|res|
  puts res.body
end
```

## Sending multiple requests and send post request after all request ends

```ruby
reqs = get("http://www.example.com/request0").
  get("http://www.example.com/request1").
  get("http://www.example.com/request2")
  
post_form(reqs.response(0).body['uri'], 
  { "id" => reqs.response(1).body['id'], 
    "uri" => reqs.response(2).body['key1'] })
```

## Check response code

```ruby
get('http://www.example.com').response.code
```