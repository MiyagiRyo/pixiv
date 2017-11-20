#!/bin/bash

#全ページ検索
collect(){
  if [ $# -eq 1 ] ; then
    num=1
    #一般ユーザーでは最大で10ページまでしか見れない
    while [ $num -gt 0 -a $num -le 10 ]
    do
      rsrt=`wget -q -O - $1$num | grep data-tags | cut -d \" -f 2`
      if [ -n "$rsrt" ] ; then
        echo $rsrt
        num=$(( num + 1 ))
      else
        num=0
      fi
    done
    unset num
  fi
}

#配列を要素ごとに改行して出力
#空行は総数のカウントに利用する
#第一引数が1なら単語(単語)の場合は括弧を含む括弧内を削除
print_ary(){
  local arrayname=$2
  eval ref=\"\${$arrayname[@]}\"
  local ary=( ${ref} )
  for i in `seq 0 ${#ary[@]}`
  do
    word=${ary[$i]}

    if [ $1 -eq 0 ] ; then
      if [ `echo $word | grep -E '^.+\(.+\)$'` ] ; then
        word=`echo $word | cut -d \( -f 1`
      fi
    fi

    echo $word $'\n'
  done
}

#与えられた文字列配列を"+"で結合した1つの文字列にして出力
unit_plus(){
  str=""
  for i in $@
  do
    str=$str$i"+"
  done
  echo ${str:0:-1}
}

#結果を整形して出力
print_result(){
  print_ary $@ | head -n -2 | sort | uniq -c | sort -r
}

#ヘルプメッセージを出力
print_help(){
  echo ""
  echo ""
  echo "   ================================================================================"
  echo "  | pixiv小説から入力されたタグ・キーワードを含む作品に付けられたタグを集計します. |"
  echo "   ================================================================================"
  echo ""
  echo "  検索したいタグ・キーワードはスペース区切りで1個以上入力して下さい."
  echo ""
  echo "  オプションは入力する検索タグ・キーワードよりも前に記述して下さい."
  echo "  以下は実装されているオプションです."
  echo "  -i : 括弧付きのタグ・キーワードを別物として集計します."
  echo "       オプション無しの場合は同一のタグとして集計します."
  echo "     例) ジークフリート(神撃のバハムート) , ジークフリート(FGO)"
  echo "         上記のようなタグを区別したいときは-i, そうでない時はなしで実行して下さい."
  echo "  -h : ヘルプ"
  echo ""
  echo "  以下は実行例です."
  echo "  \$bash get.sh ジークフリート FGO"
  echo "  \$bash get.sh -i ジークフリート"
  echo ""
  echo "  結果はヒットしたタグの個数の降順でソートされています."
  echo "  1行目の数字がヒットしたタグの総数, 2行目以降はタグの左の数字がヒットしたタグの個数です."
  echo ""
  echo ""
}

#メイン関数
main(){
  if [ $# -ge 1 ] ; then

    #処理の種類を決める変数
    flag=0

    #オプションの抽出
    while getopts ":hi" OPT ;
    do
      case $OPT in
        #ヘルプ
        h)
          print_help
          exit 0
        ;;
        #括弧付きタグの識別
        i)
        flag=$(( $falg + 1 ))
        ;;
      esac
    done

    #引数からオプション引数を取り除く
    shift $(( $OPTIND - 1 ))

    #検索タグをまとめる
    word=`unit_plus $@`

    #ベースになるURL
    url="https://www.pixiv.net/novel/search.php?s_mode=s_tag&word="$word"&order=date_d&p="
  
    #結果を収集
    result=(`collect $url`)

    #結果を表示
    if [ ${#result[@]} -eq 0 ] ; then
      echo ""
      echo "  見つかりませんでした."
      echo ""
    else
      arg=$(( $flag % 10 ))
      print_result $arg result
    fi

  else
    echo ""
    echo "  -> 検索したいタグ1個以上を引数にして下さい. <-"
    print_help
  fi
}

main $@
