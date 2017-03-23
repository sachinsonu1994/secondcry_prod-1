# rubocop:disable ClassLength
class GoogleMerchantController < ApplicationController
  def index
    respond_to do |format|
      # Keep format.html at top, as order is important for HTTP_ACCEPT headers with '*/*'
      format.html do
        if request.xhr? && params[:person_id] # AJAX request to load on person's listings for profile view
          @person = Person.find(params[:person_id])
          PersonViewUtils.ensure_person_belongs_to_community!(@person, @current_community)

          # Returns the listings for one person formatted for profile page view
          per_page = params[:per_page] || 1000 # the point is to show all here by default
          includes = [:author, :listing_images]
          include_closed = @person == @current_user && params[:show_closed]
          search = {
            author_id: @person.id,
            include_closed: include_closed,
            page: 1,
            per_page: per_page
          }

          raise_errors = Rails.env.development?

          listings =
            ListingIndexService::API::Api
            .listings
            .search(
              community_id: @current_community.id,
              search: search,
              engine: search_engine,
              raise_errors: raise_errors,
              includes: includes
            ).and_then { |res|
            Result::Success.new(
              ListingIndexViewUtils.to_struct(
              result: res,
              includes: includes,
              page: search[:page],
              per_page: search[:per_page]
            ))
            }.data

          render :partial => "listings/profile_listings", :locals => {person: @person, limit: per_page, listings: listings}
        else
          redirect_to root
        end
      end

      format.atom do
        page =  params[:page] || 1
        per_page = params[:per_page] || 50

        all_shapes = get_shapes()
        all_processes = get_processes()
        direction_map = ListingShapeHelper.shape_direction_map(all_shapes, all_processes)

        if params[:share_type].present?
          direction = params[:share_type]
          params[:listing_shapes] =
            all_shapes.select { |shape|
              direction_map[shape[:id]] == direction
            }.map { |shape| shape[:id] }
        end
        raise_errors = Rails.env.development?

        search_res = if @current_community.private
                       Result::Success.new({count: 0, listings: []})
                     else
                       ListingIndexService::API::Api
                         .listings
                         .search(
                           community_id: @current_community.id,
                           search: {
                             listing_shape_ids: params[:listing_shapes],
                             page: page,
                             per_page: per_page
                           },
                           engine: search_engine,
                           raise_errors: raise_errors,
                           includes: [:listing_images, :author, :location])
                     end

        listings = search_res.data[:listings]

        brand_hash = Hash.new
        custom_field = CustomFieldName.where("value = 'Brand'").first
        if !custom_field.blank?
          brand_value = CustomFieldValue.where("custom_field_id = #{custom_field.custom_field_id}")
          if !brand_value.blank?
            brand_value.each{|bv|
            brand_hash["#{bv.listing_id}"] = "#{bv.text_value}"
            }
          end
        end

        title = build_title(params)
        updated = listings.first.present? ? listings.first[:updated_at] : Time.now

        render layout: false,
               locals: { listings: listings,
                         title: title,
                         updated: updated,
                         brand_hash: brand_hash
                       }
      end
    end
  end

  private

  def build_title(params)
    category = Category.find_by_id(params["category"])
    category_label = (category.present? ? "(" + localized_category_label(category) + ")" : "")

    listing_type_label = if ["request","offer"].include? params['share_type']
      t("listings.index.#{params['share_type']+"s"}")
    else
      t("listings.index.listings")
    end

    t("listings.index.feed_title",
      :optional_category => category_label,
      :community_name => @current_community.name_with_separator(I18n.locale),
      :listing_type => listing_type_label)
  end

  def listings_api
    ListingService::API::Api
  end

  def transactions_api
    TransactionService::API::Api
  end

  def valid_unit_type?(shape:, unit_type:)
    if unit_type.nil?
      shape[:units].empty?
    else
      shape[:units].any? { |unit| unit[:type] == unit_type.to_sym }
    end
  end

  def get_shapes
    @shapes ||= listings_api.shapes.get(community_id: @current_community.id).maybe.or_else(nil).tap { |shapes|
      raise ArgumentError.new("Cannot find any listing shape for community #{@current_community.id}") if shapes.nil?
    }
  end

  def get_processes
    @processes ||= transactions_api.processes.get(community_id: @current_community.id).maybe.or_else(nil).tap { |processes|
      raise ArgumentError.new("Cannot find any transaction process for community #{@current_community.id}") if processes.nil?
    }
  end

  def get_shape(listing_shape_id)
    shape_find_opts = {
      community_id: @current_community.id,
      listing_shape_id: listing_shape_id
    }

    shape_res = listings_api.shapes.get(shape_find_opts)

    if shape_res.success
      shape_res.data
    else
      raise ArgumentError.new(shape_res.error_msg) unless shape_res.success
    end
  end
end
