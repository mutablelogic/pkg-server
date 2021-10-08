package deps

/* Lists the dependencies of the project */
import (
	_ "github.com/mutablelogic/go-mosquitto"
	_ "github.com/mutablelogic/go-server"
	_ "github.com/mutablelogic/go-sqlite"

	_ "github.com/GehirnInc/crypt/apr1_crypt"
	_ "github.com/dgrijalva/jwt-go"
	_ "github.com/go-ldap/ldap/v3"
	_ "github.com/gomarkdown/markdown"
	_ "github.com/miekg/dns"
	_ "github.com/rjeczalik/notify"
	_ "golang.org/x/crypto/bcrypt"
	_ "golang.org/x/net/ipv4"
	_ "golang.org/x/net/ipv6"
)
