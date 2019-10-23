require 'cgi'
require 'sinatra'
require 'active_record'

# 各種設定
PAGE_MAX = 10  # 1ページに表示できる最大件数
ID_LEN = 8     # IDの長さ
NAME_MAX = 32  # 名前の最大文字数
TEXT_MAX = 512 # 書き込みの最大文字数

set :environment, :production

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

# データベースにアクセスするためのオブジェクト
class Post < ActiveRecord::Base
end

# 現在の日時を取得
def get_time
    return Time.now.strftime("%Y/%m/%d(%a) %H:%M:%S")
end

# 数値かどうか判定
def is_number(str)
    return str =~ /^[0-9]+$/
end

# 投稿の件数に対するページ数を返す
def page_num(len)
    if len == 0
        return 1
    else
        return ((len - 1) / PAGE_MAX).to_i + 1
    end
end

# 1ページ目にリダイレクト
get '/' do
    redirect '/1'
end

# エラーページ
get '/err' do
    erb :error
end

# ページ指定
get '/:page' do
    # 数値が指定されているか
    if is_number(params[:page])
        @page = params[:page].to_i
    else
        redirect '/err'
    end

    @posts = Post.all
    @posts_len = @posts.length
    @last_page = page_num(@posts_len)

    @page_max = PAGE_MAX
    @text_max = TEXT_MAX
    @name_max = NAME_MAX

    # 無効なページ数が指定されたらエラー
    if @page <= 0 or @last_page < @page
        redirect '/err'
    end

    erb :main
end

# 前のページへ
post '/prev' do
    page = params[:page].to_i - 1

    # 範囲内ならリダイレクト
    if page >= 1
        redirect "/#{page}"
    end
end

# 次のページへ
post '/next' do
    page = params[:page].to_i + 1

    # 範囲内ならリダイレクト
    if page <= page_num(Post.all.length)
        redirect "/#{page}"
    end
end

# 新規投稿
post '/new' do
    posts = Post.all
    posts_len = posts.length
    post = Post.new

    # IDを決定
    if posts_len == 0
        post.id = format("%0#{ID_LEN}d", 1)
    else
        post.id = format("%0#{ID_LEN}d", posts[-1].id.to_i + 1)
    end

    # 入力内容を取得
    text = params[:text].slice(0, TEXT_MAX)
    text = CGI.escapeHTML(text)
    name = params[:name].slice(0, NAME_MAX)

    # データベースへ書き込み
    post.time = get_time()
    post.text = text.gsub(/(\r\n|\r|\n)/, '<br>')
    post.name = CGI.escapeHTML(name)
    post.save

    # 最新のページを表示
    redirect "/#{page_num(posts_len + 1)}"
end

# 投稿を削除
delete '/del' do
    post = Post.find(params[:id])
    post.destroy
    redirect '/'
end
