class InfosController < ApplicationController

  skip_filter :check_email_confirmation

  def rewards
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "rewards"
  end

  def returns
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "returns"
    content = if @community_customization && !@community_customization.how_to_use_page_content.nil?
      @community_customization.how_to_use_page_content.html_safe
    else
      MarketplaceService::API::Marketplaces::Helper.how_to_use_page_default_content(I18n.locale, @current_community.name(I18n.locale))
    end
    render locals: { how_to_use_content: content }
  end

  def terms
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "terms"
  end

  def privacy
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "privacy"
  end

  private

  def how_to_use_content?
    Maybe(@community_customization).map { |customization| !customization.how_to_use_page_content.nil? }
  end
end
