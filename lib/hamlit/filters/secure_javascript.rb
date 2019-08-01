# frozen_string_literal: true
module Hamlit
  class Filters
    class SecureJavascript < TextBase
      def compile(node)
        case @format
        when :xhtml
          compile_xhtml(node)
        else
          compile_html(node)
        end
      end

      private

      def compile_html(node)
        temple = [:multi]
        temple << [:static, "#{script_open_tag}>\n"]
        compile_text!(temple, node, '  ')
        temple << [:static, "\n</script>"]
        temple
      end

      def compile_xhtml(node)
        temple = [:multi]
        temple << [:static, "#{script_open_tag} type='text/javascript'>\n  //<![CDATA[\n"]
        compile_text!(temple, node, '    ')
        temple << [:static, "\n  //]]>\n</script>"]
        temple
      end

      def script_open_tag
        if nonce
          %(<script nonce="#{nonce}")
        else
          %(<script)
        end
      end

      def nonce
        RequestStore[:csp_nonce]
      end
    end

    register :secure_javascript, SecureJavascript
  end
end
