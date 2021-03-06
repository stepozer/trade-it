# User based actions fro the Tradeit API
#
#
module TradeIt
  module User
    autoload :Link, 'trade_it/user/link'
    autoload :Login, 'trade_it/user/login'
    autoload :LinkAndLogin, 'trade_it/user/link_and_login'
    autoload :Verify, 'trade_it/user/verify'
    autoload :Logout, 'trade_it/user/logout'
    autoload :Refresh, 'trade_it/user/refresh'
    autoload :Account, 'trade_it/user/account'
    autoload :Unlink, 'trade_it/user/unlink'
    autoload :Relink, 'trade_it/user/relink'

    class << self
      #
      # Parse a Tradeit Login or Verify response into our format
      #
      def parse_result(result)
        date   = Time.parse(result['Date']).to_i
        result = JSON(result.body)
        if result['status'] == 'SUCCESS'
          #
          # User logged in without any security questions
          #
          accounts = []
          if result['accounts']
            accounts = result['accounts'].map do |a|
              TradeIt::Base::Account.new(
                account_number: a['accountNumber'],
                name: a['name']
              ).to_h
            end
          end
          response = TradeIt::Base::Response.new(raw: result,
                                                 status: 200,
                                                 payload: {
                                                   type: 'success',
                                                   token: result['token'],
                                                   accounts: accounts
                                                 },
                                                 messages: [result['shortMessage']].compact)
        elsif result['status'] == 'INFORMATION_NEEDED'
          #
          # User Asked for security question
          #
          if result['challengeImage']
            data = {
              encoded: result['challengeImage']
            }
          else
            data = {
              question: result['securityQuestion'],
              answers: result['securityQuestionOptions']
            }
          end
          response = TradeIt::Base::Response.new(raw: result,
                                                 status: 200,
                                                 payload: {
                                                   type: 'verify',
                                                   challenge: result['challengeImage'] ? 'image' : 'question',
                                                   token: result['token'],
                                                   srv: date,
                                                   data: data,
                                                 },
                                                 messages: [result['shortMessage']].compact)
        else
          #
          # Login failed
          #
          raise TradeIt::Errors::LoginException.new(
            type: :error,
            code: result['code'],
            description: result['shortMessage'],
            messages: result['longMessages']
          )
        end

        # pp(response.to_h)
        response
      end
    end
  end
end
