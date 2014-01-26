require 'spec_helper'
require 'support/test_classes'

describe 'updating' do
  let(:article) { Article.new }
  let(:mapper) { Perpetuity[Article] }
  let(:new_title) { 'I has a new title!' }

  before do
    mapper.insert article
  end

  it 'updates an object in the database' do
    mapper.update article, title: new_title
    mapper.find(mapper.id_for article).title.should eq new_title
  end

  it 'resaves the object in the database' do
    article.title = new_title
    mapper.save article
    mapper.find(mapper.id_for article).title.should eq new_title
  end

  it 'only updates attributes which have changed since last retrieval' do
    first_mapper = Perpetuity[Article]
    second_mapper = Perpetuity[Article]
    article_id = first_mapper.id_for(article)
    first_article = first_mapper.find(article_id)
    second_article = second_mapper.find(article_id)

    # Change different attributes on each
    first_article.title = 'New title'
    second_article.views = 7
    first_mapper.save first_article
    second_mapper.save second_article

    canonical_article = mapper.find(article_id)
    canonical_article.title.should == 'New title'
    canonical_article.views.should == 7
  end

  it 'updates an object with referenced attributes' do
    user = User.new
    article.author = user
    mapper.save article

    retrieved_article = mapper.find(mapper.id_for article)
    retrieved_article.title = new_title
    mapper.save retrieved_article

    retrieved_article = mapper.find(mapper.id_for retrieved_article)
    retrieved_article.author.should be_a Perpetuity::Reference
  end

  it 'updates an object with an array of referenced attributes' do
    dave = User.new('Dave')
    andy = User.new('Andy')
    authors = [dave]
    book = Book.new("Title #{Time.now.to_f}", authors)
    mapper = Perpetuity[Book]

    mapper.insert book

    retrieved_book = mapper.find(mapper.id_for book)
    retrieved_book.authors << andy
    mapper.save retrieved_book

    retrieved_authors = Perpetuity[Book].find(mapper.id_for retrieved_book).authors
    retrieved_authors.map(&:klass).should be == [User, User]
    retrieved_authors.map(&:id).should be == [mapper.id_for(dave), mapper.id_for(andy)]
  end

  describe 'atomic increments/decrements' do
    let(:view_count) { 0 }
    let(:article) { Article.new('title', 'body', nil, nil, view_count) }

    it 'increments attributes of objects in the database' do
      mapper.increment article, :views
      mapper.increment article, :views, 10
      mapper.find(mapper.id_for(article)).views.should == view_count + 11
    end

    it 'decrements attributes of objects in the database' do
      mapper.decrement article, :views
      mapper.decrement article, :views, 10
      mapper.find(mapper.id_for(article)).views.should == view_count - 11
    end
  end
end
