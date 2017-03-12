require 'spec_helper'

describe Hknife do
  it 'has a version number' do
    expect(Hknife::VERSION).not_to be nil
  end
      
  it 'send get request to specified uri' do
    extend Hknife::Delegator
    stub_request(:get, "http://www.example.com/").
      to_return(
        status: 200,
      )
    res = get('http://www.example.com/').response
    expect(res.code).to eq "200"
  end

  it 'send put request to specified uri' do
    extend Hknife::Delegator    
    stub_request(:put, "http://www.example.com/").
      to_return(
        body: '{ "uri": "http://www.example.com/", "id": "abc" }',
        status: 200,
        headers: { 'Content-Type' => 'application/json' }
      )
    res = put('http://www.example.com/', {"id" => "abc"}).response
    expect(res.code).to eq "200"
    expect(res.body['id']).to eq "abc"
  end

  it 'send post request to specified uri' do
    extend Hknife::Delegator    
    stub_request(:post, "http://www.example.com/").
      to_return(
        body: '{ "uri": "http://www.example.com/", "id": "abc" }',
        status: 200,
        headers: { 'Content-Type' => 'application/json' }
      )
    res = post_form('http://www.example.com/', {"id" => "abc"}).response
    expect(res.code).to eq "200"
    expect(res.body['id']).to eq "abc"
  end

  it 'send get request then post request w/o exception' do
    extend Hknife::Delegator    
    stub_request(:any, "http://www.example.com/")    
    get('http://www.example.com/').
      post_form('http://www.example.com/', {"id" => "abc"})
  end

  it 'creates base object w/o exception' do
    extend Hknife::Delegator    
    stub_request(:get, "http://www.example.com/").
      to_return(
        body: '{ "uri": "http://www.example.com/", "id": 123 }',
        status: 200,
        headers: { 'Content-Type' => 'application/json' }
      )
      
    stub_request(:post, "http://www.example.com/").
      to_return(
        status: 200,
      )

    res = get('http://www.example.com/').response
    expect(res.code).to eq "200"
    expect(res.body['uri']).to eq "http://www.example.com/"
    expect(res.body['id']).to eq 123

    res = post_form(res.body['uri'], {"id" => res.body['id']}).response
    expect(res.code).to eq "200"
  end

  it 'specify header' do
    extend Hknife::Delegator   
    stub = stub_request(:get, "http://www.example.com/").
            with(headers: { 'Host' => 'www.example.co.jp'})
    res = get('http://www.example.com/').
            header({'Host' => 'www.example.co.jp'}).
            response
    expect(stub).to have_been_requested
  end  

  it 'send multiple reqeusts at same time' do
    extend Hknife::Delegator   
    stub_request(:get, "http://www.example.com/request0").
      to_return(
        body: '{ "uri": "http://www.example.com/", "id": 123 }',
        status: 200,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, "http://www.example.com/request1").
      to_return(
        body: '{ "uri": "http://www.example.com/", "id": 123 }',
        status: 200,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, "http://www.example.com/request2").
      to_return(
        body: '{ "uri": "http://www.example.com/", "key": "value" }',
        status: 200,
        headers: { 'Content-Type' => 'application/json' }
      )    

    reqs = get('http://www.example.com/request0').
            get('http://www.example.com/request1').
            get('http://www.example.com/request2')

    reqs.send

    stub = stub_request(:post, "http://www.example.com/").
            with(body: 'id=123&uri=value')

    req = post_form(reqs.response(0).body['uri'], 
      { "id" => reqs.response(1).body['id'], 
        "uri" => reqs.response(2).body['key'] })
    
    req.response

    expect(stub).to have_been_requested
  end   
end
