import java.util.*;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.Request; 
import net.glxn.qrgen.QRCode;
import java.net.URL;
import org.cometd.common.*;
import org.cometd.server.*;
import java.rmi.server.UID;
import intel.pcsdk.*;
import TUIO.*;

String HOST_IP = "10.0.9.47";

PXCUPipeline pp = null;
PImage rgb=null;
PImage QRImg = null;

String drinkName = null;

public class EchoService extends AbstractService
{
  public EchoService(BayeuxServer bayeuxServer)
  {
    super(bayeuxServer, "echo");
    addService("/echo", "processEcho");
  }

  public void processEcho(final ServerSession remote, final Map<String, Object> data)
  {
    println(this.toString());
    new Thread(new Runnable() {
      int count = 0;
      @Override
        public void run() {
        while (true) {
          if (drinkName != null)
//          if (true) 
          {
            Map drink = new HashMap<String, Object>();
            drink.put("name", drinkName);
            drink.put("qty", 1);
//            ClientSessionChannel channel = getLocalSession().getChannel("/echo");
//            channel.publish(drink);
            remote.deliver(getServerSession(), "/echo", drink, null);

            drinkName = null;
            println(drink.toString());
          }          
          println(count);
          count++;
          try {
            Thread.sleep(2000);
          } 
          catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      }
    }
    ).start();
  }
}

public class DrinksServlet extends HttpServlet {
  public void init() throws ServletException
  {
    super.init();
    // Grab the Bayeux object
    BayeuxServer bayeux = (BayeuxServer)getServletContext().getAttribute(BayeuxServer.ATTRIBUTE);
    new EchoService(bayeux);
    // Create other services here

    // This is also the place where you can configure the Bayeux object
    // by adding extensions or specifying a SecurityPolicy
  }

  public void service(ServletRequest request, ServletResponse response) throws ServletException, IOException
  {
    throw new ServletException();
  }
};




class QRHandler extends AbstractHandler
{
  public void handle(String target, Request req, HttpServletRequest request, HttpServletResponse response)
    throws IOException, ServletException
  {   
    if (request.getParameter("qr") == null) return;
    //String token = new UID().toString();
    String token = request.getParameter("access_token");    
    println(token);
    URL url = new URL("http://localhost:8080?token=" + token);
    response.setContentType("image/png");
    response.setStatus(HttpServletResponse.SC_OK);
    QRCode.from(url.toString()).to(ImageType.PNG).withSize(250, 250).writeTo(response.getOutputStream());
    ((Request)request).setHandled(true);
  }
};

class OrderHandler extends AbstractHandler {
  public void handle(String target, Request req, HttpServletRequest request, HttpServletResponse response)
    throws IOException, ServletException
  {
    if (request.getMethod().toUpperCase().equals("OPTIONS")) {
      response.setHeader("Access-Control-Allow-Origin", "*");
      response.setHeader("Access-Control-Allow-Methods", "*"); 
      response.setHeader("Access-Control-Allow-Headers", "Content-Type");

      ((Request)request).setHandled(true); 
      response.setStatus(HttpServletResponse.SC_OK);
      return;
    }    

    if (request.getParameter("order") == null) return;
    if (!request.getMethod().toUpperCase().equals("POST")) return;

    JSONArray drinks = new JSONArray(request.getReader());
    println(drinks.toString());
    if (request.getParameter("order") == null) return;

    String token = request.getParameter("access_token");

    response.setContentType("application/json");
    response.getWriter().println(drinks.toString());

    ((Request)request).setHandled(true); 
    response.setStatus(HttpServletResponse.SC_OK);
  }
};


void setup() {
  size(640, 480);

  pp = new PXCUPipeline(this);
  if (!pp.Init(PXCUPipeline.GESTURE|PXCUPipeline.COLOR_VGA)) {
    print("Failed to initialize PXCUPipeline\n");
  }

  TuioProcessing tuioClient = new TuioProcessing(this, 3333);

  int[] csize=new int[2];
  if (pp.QueryRGBSize(csize)) {
    print("RGBSize("+csize[0]+","+csize[1]+")\n");
    rgb=createImage(csize[0], csize[1], RGB);
  }

  Server server = new Server(8080);

  ResourceHandler resource_handler = new ResourceHandler();
  resource_handler.setDirectoriesListed(true);
  resource_handler.setWelcomeFiles(new String[] { 
    "index.html"
  }
  );
  resource_handler.setResourceBase(sketchPath(""));

  //  Map clientOptions = new HashMap();
  //  JSONContext.Client jsonContext = new JacksonJSONContextClient();
  //  clientOptions.put(ClientTransport.JSON_CONTEXT, jsonContext);
  //  BayeuxClient client = new BayeuxClient(cometdURL, transport);

  ContextHandlerCollection contexts = new ContextHandlerCollection();
  //  server.setHandler(contexts);

  ServletContextHandler context = new ServletContextHandler(contexts, "/", ServletContextHandler.SESSIONS);  
  context.addServlet("org.eclipse.jetty.servlet.DefaultServlet", "/");

  CometdServlet cometdServlet = new CometdServlet();
  ServletHolder cometd_holder = new ServletHolder(cometdServlet);
  //  cometd_holder.setInitParameter("timeout", "200000");
  //  cometd_holder.setInitParameter("interval", "100");
  //  cometd_holder.setInitParameter("maxInterval", "100000");
  //  cometd_holder.setInitParameter("multiFrameInterval", "1500");
  cometd_holder.setInitParameter("logLevel", "1");
  cometd_holder.setInitOrder(1);
  context.addServlet(cometd_holder, "/cometd/*");

  ServletHolder drinks_holder = new ServletHolder(new DrinksServlet());
  drinks_holder.setInitOrder(2);
  drinks_holder.setInitParameter("logLevel", "3");
  context.addServlet(drinks_holder, "/service/*");

  HandlerCollection handlers = new HandlerCollection();
  handlers.setHandlers(new Handler[]
  { 
    new QRHandler(), 
    new OrderHandler(), 
    context, 
    //    resource_handler
  }
  );

  try {
    context.setBaseResource(new ResourceCollection(new org.eclipse.jetty.util.resource.Resource[]
    {
      org.eclipse.jetty.util.resource.Resource.newResource(sketchPath("")),
    }
    ));
  }
  catch(Exception e) {
    e.printStackTrace();
  } 
  server.setHandler(handlers);

  try {
    server.start();
    //server.join();
  } 
  catch(Exception e) {
    println("Could not start http server. Reason: " + e.toString());
  };

  BayeuxServer bayeux = cometdServlet.getBayeux();
  bayeux.setSecurityPolicy(new DefaultSecurityPolicy());
}

void draw() {
  if (pp.AcquireFrame(false)) {

    if (pp.QueryRGB(rgb))
      image(rgb, 0, 0);

    PXCMGesture.Gesture gdata = new PXCMGesture.Gesture();
    if (pp.QueryGesture(PXCMGesture.Gesture.LABEL_ANY, gdata)) {
      if (gdata.label == PXCMGesture.Gesture.LABEL_HAND_WAVE) {
        //println(gdata.label);
        //println(gdata.timeStamp);
        try {
          //          URL url = new URL("http://localhost:8080?token=" + (new UID()).toString());
          URL url = new URL("http://" + HOST_IP + ":8080?token=" + (new UID()).toString());
          File imgFile = QRCode.from(url.toString()).to(ImageType.PNG).file();
          QRImg = loadImage(imgFile.getAbsolutePath());
        } 
        catch(Exception e) {
          e.printStackTrace();
        }
      }
    }

    pp.ReleaseFrame();
  }

  if (QRImg!=null)
    image(QRImg, 0, 0);
}

void addTuioObject(TuioObject tobj) {
  println("add object "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle());
  drinkName = "Beer";
}

