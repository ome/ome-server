#!/usr/bin/perl -w

use XML::LibXML;
use strict;

use vars qw{%char_entities};

%char_entities = (
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
);

sub process_cgi_call {
    my ($methods) = @_;
    #my $coder;
    
    #$coder = Frontier::RPC2->new;
    
    # Get our CGI request information.
    my $method = $ENV{'REQUEST_METHOD'};
    my $type = $ENV{'CONTENT_TYPE'};
    my $length = $ENV{'CONTENT_LENGTH'};
    
    # Perform some sanity checks.
    http_error(405, "Method Not Allowed") unless $method eq "POST";
    http_error(400, "Bad Request") unless $type eq "text/xml";
    http_error(411, "Length Required") unless $length > 0;
    
    # Fetch our body.
    my $body;
    my $count = read STDIN, $body, $length;
    http_error(400, "Bad Request") unless $count == $length;

    my ($methodName, $params) = decode_call($body);

    my @result;
    {
	no strict 'refs';
	@result = &{$methods->{$methodName}}(@$params);
	print "@result\n";
    }
    #send_xml(encode_fault(3,"Boo"));
    send_xml(encode_response(\@result));
}

sub _item ($$) {
    my $doc = shift; my $item = shift;

    my $ref = ref($item);
    if (!$ref) {
	return _scalar($doc,$item);
    } elsif ($ref eq 'ARRAY') {
	return _array($doc,$item);
    } elsif ($ref eq 'HASH') {
	return _hash($doc,$item);
#    } elsif ($ref eq 'Frontier::RPC2::Boolean') {
#	push @text, "<value><boolean>", $item->repr, "</boolean></value>\n";
#    } elsif ($ref eq 'Frontier::RPC2::String') {
#      push @text, "<value><string>", $item->repr, "</string></value>\n";
#    } elsif ($ref eq 'Frontier::RPC2::Integer') {
#      push @text, "<value><int>", $item->repr, "</int></value>\n";
#    } elsif ($ref eq 'Frontier::RPC2::Double') {
#      push @text, "<value><double>", $item->repr, "</double></value>\n";
#    } elsif ($ref eq 'Frontier::RPC2::DateTime::ISO8601') {
#	push @text, "<value><dateTime.iso8601>", $item->repr, "</dateTime.iso8601></value>\n";
#    } elsif ($ref eq 'Frontier::RPC2::Base64') {
#	push @text, "<value><base64>", $item->repr, "</base64></value>\n";
    } else {
	die "can't convert \`$item' to XML\n";
    }
}

sub _text ($) {
    my $str = shift;
    $str =~ s/([&<>\"])/$char_entities{$1}/ge;
    return new XML::LibXML::Text($str);
}

sub _hash ($$) {
    my $doc = shift; my $hash = shift;

    my $value = $doc->createElement("value");
    my $struct = $doc->createElement("struct");
    my ($k,$v,$member,$name,$kvalue);

    while (($k, $v) = each %$hash) {
	$member = $doc->createElement("member");
	$name = $doc->createElement("name");
	$name->appendChild(_text($k));
	$kvalue = _item($doc,$v);
	$member->appendChild($name);
	$member->appendChild($kvalue);
	$struct->appendChild($member);
    }

    $value->appendChild($struct);

    return $value;
}


sub _array ($$) {
    my $doc = shift; my $items = shift;

    my $value = $doc->createElement("value");
    my $array = $doc->createElement("array");
    my $data = $doc->createElement("data");

    my $item;
    foreach $item (@$items) {
	$data->appendChild(_item($doc,$item));
    }

    $array->appendChild($data);
    $value->appendChild($array);

    return $value;
}

sub _scalar ($$) {
    my $doc   = shift;
    my $value = shift;

    my $vnode = $doc->createElement("value");
    my $node;
    
    # these are from `perldata(1)'
    if ($value =~ /^[+-]?\d+$/) {
	$node = $doc->createElement("i4");
    } elsif ($value =~ /^(-?(?:\d+(?:\.\d*)?|\.\d+)|([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?)$/) {
	$node = $doc->createElement("double");
    } else {
	$node = $doc->createElement("string");
    }

    $node->appendChild(_text($value));
    $vnode->appendChild($node);
    return $vnode;
}

sub encode_fault ($$) {
    my $code = shift;
    my $msg  = shift;

    my $doc = new XML::LibXML::Document;
    my $root = $doc->createElement("methodResponse");
    my $fault = $doc->createElement("fault");
    $fault->appendChild(_item($doc,{"faultCode" => $code, "faultString" => $msg}));
    $root->appendChild($fault);
    $doc->setDocumentElement($root);

    return $doc->toString;
}

sub encode_response ($) {
    my $result = shift;
    my $doc = new XML::LibXML::Document;
    my $root = $doc->createElement("methodResponse");
    $root->appendChild(_params($doc,$result));
    $doc->setDocumentElement($root);

    return $doc->toString;
}

sub encode_call ($$) {
    my $method = shift;
    my $params = shift;

    my $doc = new XML::LibXML::Document;
    my $root = $doc->createElement("methodCall");
    my $methodName = $doc->createElement("methodName");
    $methodName->appendChild(_text($method));
    $root->appendChild($methodName);
    $root->appendChild(_params($doc,$params));
    $doc->setDocumentElement($root);

    return $doc->toString;
}

sub _params ($$) {
    my $doc    = shift;
    my $result = shift;

    my $params = $doc->createElement("params");

    foreach my $item (@$result) {
	my $param = $doc->createElement("param");
	$param->appendChild(_item($doc,$item));
	$params->appendChild($param);
    }

    return $params;
}

sub decode_call ($) {
    my $body = shift;
    my $parser = new XML::LibXML;
    my $tree = $parser->parse_string($body);
    my $root = $tree->getDocumentElement;

    my $methodName = $root->findvalue("methodName");
    my $paramNodes = $root->findnodes("params/param");
    my @params;
    
    foreach my $param (@$paramNodes) {
	my $v = undef;

	my $datatypes = ["i4","int","string","boolean","double","base64","dateTime.iso8601"];

	foreach my $dt (@$datatypes) {
	    my $temp = $param->findvalue("value/$dt");
	    if ($temp) {
		$v = $temp;
	    }
	}

	push @params, $v;
    }

    return ($methodName,\@params);
}

sub perform_call ($$) {
    my $methodName = shift;
    my $params = shift;
    my $result;
    print "$methodName\n$params\n";
    eval { $result = &{$methodName}(@{$params}); };
    return $result;
}

# Send an HTTP error and exit.
sub http_error ($$) {
    my ($code, $message) = @_;
    print <<"EOD";
Status: $code $message
Content-type: text/html

<title>$code $message</title>
<h1>$code $message</h1>
<p>Unexpected error processing XML-RPC request.</p>
EOD
    exit 0;
}

# Send an XML document (but don't exit).
sub send_xml ($) {
    my ($xml_string) = @_;
    my $length = length($xml_string);
    print <<"EOD";
Status: 200 OK
Content-type: text/xml
Content-length: $length

EOD
    # We want precise control over whitespace here.
    print $xml_string;
}

sub mynew ($) {
    my $pack = shift;
    my $cons = "${pack}::new";
    
    no strict 'refs';
    return &$cons($pack);
}

process_cgi_call({
    "Test.test" => \&test
    });

#my $doc = mynew("XML::LibXML::Document");
#my $array = {'a'=>'b', 'c'=>'d', 'e'=>[1,2,3]};
#my $root = _item($doc,$array);
#$doc->setDocumentElement($root);
#my $q = $root->findvalue("value/struct/member/name");
#if (defined $q) {
#    print "'$q'\n";
#} else {
#    print "b\n";
#}
#print $doc->toString;

#print encode_fault(3,"boo");

#print encode_response([1,2,"South Dakota"]);

#my $c = encode_call("test",[3,4]);
#my ($m,$p) = decode_call($c);
#my $result = perform_call($m,$p);
#print "$m\n$p\n$result\n";

#my $coder = Frontier::RPC2->new;
#send_xml($coder->encode_response(3));

sub test {
    my $x = shift;
    my $y = shift;
    print "yo\n";
    return [$x+$y,$x-$y];
}
