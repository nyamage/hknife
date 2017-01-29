# hknife

It's DSL to create HTTP request pipline.
There is no implementation. There is an only idea.
If there is feature you want, please create issue.

# How to use

## Sending get request

get('http://www.example.com')

## Sending get request and post request with reponse of previous get request

get('http://www.example.com').
  post('http://www.example.com/', response('id'))

## Sending named get request and post request with the response

name('named_get_request').
  get('http://www.example.com')

name('named_get_request') do |request, response|
  post(response('url'), response('id'))
end

## Sending get request with customer header

header(Host: 'www.example.com').get('http://93.184.216.34/')

## Sending request asynchronously

get("http://www.example.com/request1") do |res|
  get("http://www.example.com/after_request1") do|res|
    
  end
end

## Sending multiple get requests and send post request after all request ends

parallel do
  name('request1').get("http://www.example.com/request1")
  name('request2').get("http://www.example.com/request2")  
end.
  post('http://www.example.com/', 
    name('request1').response('id'), 
    name('request2').response('key1'))


## Check 404 error

get('http://www.example.com').
  response.status