#-*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'json'

$x = 0
$y = 0
$get_hash = {}

get '/' do
    'lingrbot id is onsg7bot'
end

post '/' do
    json = JSON.parse(params[:json])
    tmp = ""
    json["events"].each do |e|
        if e["message"]
            m = e['message']['text']
            if /^right/ =~ m
                $x += 1
                tmp = $x.to_s
            elsif /^left/ =~ m
                $x -= 1
                tmp = $x.to_s
            elsif /^([0-9]+) right/ =~ m
                $x += $1.to_i
                tmp = $x.to_s
            elsif /^([0-9]+) left/ =~ m
                $x -= $1.to_i
                tmp = $x.to_s
           elsif /^([0-9]) up/ =~ m
                $y += $1.to_i
                tmp = $y.to_s
            elsif /^([0-9]) down/ =~ m
                $y -= $1.to_i
                tmp = $y.to_s
            elsif /^up/ =~ m
                $y += 1
                tmp = $y.to_s
            elsif /^down/ =~ m
                $y -= 1
                tmp = $y.to_s
            elsif /^([0-9]+) set/ =~ m
                $x = $1.to_i
                tmp = $x.to_s
            elsif /^([0-9a-zA-Z_ ]+) get/ =~ m
                if $get_hash[$1].nil?
                    tmp = "おめでとうございます！"
                    $get_hash[$1] = e["message"]["nickname"]
                    $get_hash[e["message"]["nickname"]] = e["message"]["nickname"]
                else
                    tmp = "#{$get_hash[$1]}が取得済みです！"
                end
            elsif /\?$/ =~ m
            elsif /(hey|hi)/ =~ m
                tmp = "hi"
                $x = rand(100)
                $y = rand(100)
            elsif /^(show|view)/ =~ m
                tmp = "#{$x},#{$y}"
            else
                tmp = ""
            end
        end
    end
    tmp
end
