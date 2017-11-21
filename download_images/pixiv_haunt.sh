#!/bin/bash

USER_AGENT='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; NP06; rv:11.0) like Gecko'
DIRECTORY_PATH=""
HTML_SOURCE=""

#引数から作業場所を変数に格納する
setDIRECTORY_PATH(){
  if [ $# = 1 ]; then    #パス指定がない場合
    DIRECTORY_PATH="."     #カレントディレクトリに設定
  elif [ $# = 2 ]; then  #パス指定がある場合
    #絶対パス指定または ~/hoge , ./hoge指定の場合
    if [ ${2:0:1} = "/" -o ${2:0:1} = "~" -o ${2:0:2} = "./" ]; then
      DIRECTORY_PATH=$2
    #上記以外の相対パス指定の場合
    else
      DIRECTORY_PATH="./"$2
    fi
    #パスの終末を"/"にする(表記の統一)
    if [ ${DIRECTORY_PATH:${#DIRECTORY_PATH}-1} != "/" ]; then
      DIRECTORY_PATH=$DIRECTORY_PATH"/"
    fi
  else
    echo "---- BAD ARGUMENTS! ----"
    exit 1
  fi
}

#対象作品のURLからHTMLを変数に格納
getHTMLSource(){
  HTML_SOURCE=`curl -sS -H "'UserAgent: $USER_AGENT'" $1`
  echo "get the target HTML."
}

#作品のタイトルを取得(結果を格納するディレクトリ名に使用)
getTitle(){
  echo $HTML_SOURCE |
  grep -o "<title>[^<]*<\/title>" |
  sed -e 's/<\/*title>//g'
}

#作業ディレクトリの作成と移動
setDirectory(){
  cd $DIRECTORY_PATH
  title=`getTitle`
  if [ -n "`ls | grep $title`" ]; then
    echo "  directory \" $title \" already exists."
    title=$title"_""`date +%T.%N`"
    echo "  so now make directory name with timestanp."
  fi
  mkdir $title && cd $_
  echo "make new dirctory \" $DIRECTORY_PATH$title \"."
}

#各画像のURLを取得
getImagesURLs(){
  echo $HTML_SOURCE |
  grep \<body\> | grep -o "<script>[^<]*<\/script>" |
  cut -d \  -f3 | cut -d \" -f2 | grep ^https
}

#画像をダウンロードする
downloadImages(){
  count=0
  for url in `getImagesURLs`
  do
    url=`echo $url | sed -e 's/\\\//g'`
    image_name=$count.${url##*.}
    curl -sS --referer $1 -o $image_name $url
    count=$(( count + 1 ))
    echo "  ${count}pages downloaded..."
  done
  echo "All image downloading is complete!"
}

#メイン関数
main(){
  #作業ディレクトリの特定とその値を変数に格納
  setDIRECTORY_PATH $@
  #対象作品のページからHTML文を取得
  getHTMLSource $1
  #画像の保存先のディレクトリの作成と移動
  setDirectory
  #画像をダウンロード
  downloadImages $1
  exit 0
}

#プログラムの実行部分(メイン関数を呼び出す)
main $@
