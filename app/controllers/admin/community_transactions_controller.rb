require 'csv'

class Admin::CommunityTransactionsController < ApplicationController
  TransactionQuery = MarketplaceService::Transaction::Query
  before_filter :ensure_is_admin

  def index
    @selected_left_navi_link = "transactions"
    pagination_opts = PaginationViewUtils.parse_pagination_opts(params)

    conversations = if params[:sort].nil? || params[:sort] == "last_activity"
      TransactionQuery.transactions_for_community_sorted_by_activity(
        @current_community.id,
        sort_direction,
        pagination_opts[:limit],
        pagination_opts[:offset])
    else
      TransactionQuery.transactions_for_community_sorted_by_column(
        @current_community.id,
        simple_sort_column(params[:sort]),
        sort_direction,
        pagination_opts[:limit],
        pagination_opts[:offset])
    end

    bank_detail_hash = Hash.new
    bank_details = BraintreeAccount.all
    bank_details.each{|bank_detail|
    bank_detail_hash["#{bank_detail.person_id}"] = {:ifsc_number => bank_detail.ifsc_number, :account_number => bank_detail.account_number, :bank_name_and_branch => bank_detail.bank_name_and_branch}
    }

    count = TransactionQuery.transactions_count_for_community(@current_community.id)

    # TODO THIS IS COPY-PASTE
    conversations = conversations.map do |transaction|
      conversation = transaction[:conversation]
      # TODO Embed author and starter to the transaction entity
      # author = conversation[:other_person]
      author = Maybe(conversation[:other_person]).or_else({is_deleted: true})
      starter = Maybe(conversation[:starter_person]).or_else({is_deleted: true})

      [author, starter].each { |p|
        p[:url] = person_path(p[:username]) unless p[:username].nil?
        p[:display_name] = PersonViewUtils.person_entity_display_name(p, "fullname")
      }

      if transaction[:listing].present?
        # This if was added to tolerate cases where listing has been deleted
        # due the author deleting his/her account completely
        # UPDATE: December 2014, we did an update which keeps the listing row even if user is deleted.
        # So, we do not need to tolerate this anymore. However, there are transactions with deleted
        # listings in DB, so those have to be handled.
        transaction[:listing_url] = listing_path(id: transaction[:listing][:id])
      end

      transaction[:last_activity_at] = last_activity_for(transaction)

      transaction.merge({author: author, starter: starter})
    end

    conversations = WillPaginate::Collection.create(pagination_opts[:page], pagination_opts[:per_page], count) do |pager|
      pager.replace(conversations)
    end

    respond_to do |format|
      format.html do
        render("index", {
          locals: {
            community: @current_community,
            conversations: conversations
          }
        })
      end
        format.csv do
          marketplace_name = if @current_community.use_domain
            @current_community.domain
          else
            @current_community.ident
          end

          self.response.headers["Content-Type"] ||= 'text/csv'
          self.response.headers["Content-Disposition"] = "attachment; filename=#{marketplace_name}-transactions-#{Date.today}.csv"
          self.response.headers["Content-Transfer-Encoding"] = "binary"
          self.response.headers["Last-Modified"] = Time.now.ctime.to_s

          self.response_body = Enumerator.new do |yielder|
            generate_csv_for(yielder, conversations, bank_detail_hash)
          end
        end
    end
  end

  def generate_csv_for(yielder, conversations, bank_detail_hash)
    # first line is column names
    yielder << %w{
      transaction_id
      listing_id
      listing_title
      status
      currency
      sum
      started_at
      updated_at
      last_activity_at
      starter_username
      other_party_username
      other_party_first_name
      other_party_last_name
      other_party_phone_number
      bank_name_and_branch
      ifsc_number
      account_number
    }.to_csv(force_quotes: true)
    conversations.each do |conversation|
      if !bank_detail_hash["#{conversation[:listing][:author_id]}"].blank? && !bank_detail_hash["#{conversation[:listing][:author_id]}"][:ifsc_number].blank?
        ifsc_number = bank_detail_hash["#{conversation[:listing][:author_id]}"][:ifsc_number]
      else
        ifsc_number = nil
      end

      if !bank_detail_hash["#{conversation[:listing][:author_id]}"].blank? && !bank_detail_hash["#{conversation[:listing][:author_id]}"][:bank_name_and_branch].blank?
        bank_name_and_branch = bank_detail_hash["#{conversation[:listing][:author_id]}"][:bank_name_and_branch]
      else
        bank_name_and_branch = nil
      end

      if !bank_detail_hash["#{conversation[:listing][:author_id]}"].blank? && !bank_detail_hash["#{conversation[:listing][:author_id]}"][:account_number].blank?
        account_number = bank_detail_hash["#{conversation[:listing][:author_id]}"][:account_number]
      else
        account_number = nil
      end

      yielder << [
        conversation[:id],
        conversation[:listing] ? conversation[:listing][:id] : "N/A",
        conversation[:listing_title] || "N/A",
        conversation[:order_status],
        conversation[:payment_total].is_a?(Money) ? conversation[:payment_total].currency : "N/A",
        conversation[:payment_total],
        conversation[:created_at],
        conversation[:updated_at],
        conversation[:last_activity_at],
        conversation[:starter] ? conversation[:starter][:username] : "DELETED",
        conversation[:author] ? conversation[:author][:username] : "DELETED",
        conversation[:author] ? conversation[:author][:first_name] : "DELETED",
        conversation[:author] ? conversation[:author][:last_name] : "DELETED",
        conversation[:author] ? conversation[:author][:phone_number] : "DELETED",
        bank_name_and_branch,
        ifsc_number,
        account_number
      ].to_csv(force_quotes: true)
    end
  end

  private

  def last_activity_for(conversation)
    last_activity_at = 0
    last_activity_at = if conversation[:conversation][:last_message_at].nil?
      conversation[:last_transition_at]
    elsif conversation[:last_transition_at].nil?
      conversation[:conversation][:last_message_at]
    else
      [conversation[:last_transition_at], conversation[:conversation][:last_message_at]].max
    end
    last_activity_at
  end

  def simple_sort_column(sort_column)
    case sort_column
    when "listing"
      "listings.title"
    when "started"
      "created_at"
    end
  end

  def sort_direction
    params[:direction] || "desc"
  end
end
